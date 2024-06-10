codeunit 51119 "ABS File Management"
{
    trigger OnRun()
    begin

    end;

    var
        ABSBlobClient: Codeunit "ABS Blob Client";
        AFSFileClient: Codeunit "AFS File Client";
        ABSBlobContainerClient: Codeunit "ABS Container Client";
        FileMgt: Codeunit "File Management";
        FileDoesNotExistErr: Label 'The blob file %1 does not exist.', Comment = '%1 File Path';
        Text013: Label 'The file name %1 already exists.';
        AllFilesFilterTxt: Label '*.*', Locked = true;

    procedure ChangeConnectionValues(StorageAccountName: Text[250]; ContainerName: Text[250]; SharedKey: Text[250])
    var
        ABSConnectorSetup: Record "ABS Connector Setup";
    begin
        ABSConnectorSetup.Get();
        InitializeConnection(StorageAccountName, ContainerName, SharedKey);
        InitializeConnectionManually(StorageAccountName, ContainerName, SharedKey);
    end;

    procedure InitializeConnection()
    var
        ABSConnectorSetup: Record "ABS Connector Setup";
    begin
        ABSConnectorSetup.Get();
        InitializeConnection(ABSConnectorSetup."Account Name", ABSConnectorSetup."Container Name", ABSConnectorSetup."Shared Key");
    end;

    procedure InitializeConnection(StorageAccountName: Text[250]; ContainerName: Text[250]; SharedKey: Text[250])
    var
        Authorization: Interface "Storage Service Authorization";
        StorageServiceAuthorization: Codeunit "Storage Service Authorization";
        ABSContainers: Record "ABS Container" temporary;
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        Authorization := StorageServiceAuthorization.CreateSharedKey(SharedKey);
        ABSBlobContainerClient.Initialize(StorageAccountName, Authorization);

        ABSOperationResponse := ABSBlobContainerClient.ListContainers(ABSContainers);
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());

        if ABSContainers.FindSet() then begin
            ABSContainers.SetRange(Name, ContainerName);
            if not ABSContainers.FindFirst() then
                ABSBlobContainerClient.CreateContainer(ContainerName);
        end;

        ABSBlobClient.Initialize(StorageAccountName, ContainerName, Authorization);
    end;

    procedure InitializeConnectionManually(StorageAccountName: Text[250]; ContainerName: Text[250]; SharedKey: Text[250])
    var
        httpContent: HttpContent;
        jsonBody: text;
        httpResponse: HttpResponseMessage;
        httpHeader: HttpHeaders;
        response: Text;
        httpClient: HttpClient;
        jsonObject: JsonObject;
        uri: Text;
        AzureFuncSetup: Record "Azure Function Connector Setup";
    begin
        AzureFuncSetup.Get();
        jsonObject.Add('accountName', StorageAccountName);
        jsonObject.Add('accountKey', SharedKey);
        jsonObject.Add('containerName', ContainerName);
        jsonObject.WriteTo(jsonBody);
        httpContent.WriteFrom(jsonBody);
        httpContent.GetHeaders(httpHeader);
        httpHeader.Remove('Content-Type');
        httpHeader.Add('Content-Type', 'application/json');
        uri := StrSubstNo('%1AzureChangeConfigValues?code=%2', AzureFuncSetup."Base Url", AzureFuncSetup."Function Key");
        httpClient.Put(uri, httpContent, httpResponse);
        if not httpResponse.IsSuccessStatusCode then begin
            httpResponse.Content.ReadAs(response);
            Error('%1 %2. %3', httpResponse.HttpStatusCode, httpResponse.ReasonPhrase, response);
        end;
    end;

    procedure GetContainersList(var ABSConnectorList: Record "ABS Connector List")
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
        ABSContainer: Record "ABS Container" temporary;
    begin
        InitializeConnection();

        ABSConnectorList.Reset();
        ABSConnectorList.DeleteAll();

        ABSOperationResponse := ABSBlobContainerClient.ListContainers(ABSContainer);
        if ABSContainer.FindSet() then
            repeat
                ABSConnectorList.Init();
                ABSConnectorList.Name := ABSContainer.Name;
                ABSConnectorList."Last Modified" := ABSContainer."Last Modified";
                if ABSConnectorList.Insert(true) then;
            until ABSContainer.Next() = 0;
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());
    end;

    //Replaces File - CreateTempFile
    procedure CreateTempBlobFile() ABSBlobList: Record "ABS Connector List";
    var
        TempBlobName: Text;
        InStream: InStream;
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlobName := Format(CreateGuid());
        TempBlobName := Magicpath() + '/' + TempBlobName + '.tmp';
        TempBlob.CreateInStream(InStream);
        SaveBlobFromInStream(TempBlobName, InStream);
        GetDirectoryBlobFilesList(ABSBlobList);
        ABSBlobList.SetRange("Full Name", TempBlobName);
    end;

    //Replaces File Management - ServerTempFileName
    procedure TempBlobFileName(FileExtension: Text) BlobFileName: Text
    var
        TempFileName: Text;
        InStream: InStream;
        TempBlob: Codeunit "Temp Blob";
    begin
        TempFileName := Format(CreateGuid());
        BlobFileName := FileMgt.CreateFileNameWithExtension(TempFileName, FileExtension);
        BlobFileName := Magicpath() + '/' + TempFileName;
        TempBlob.CreateInStream(InStream);
        SaveBlobFromInStream(BlobFileName, InStream);
    end;

    //Replaces File Management - DownloadTempFile
    procedure DownloadTempBlobFile(BlobFileName: Text): Text
    var
        FullBlobFileName: Text;
    begin
        InitializeConnection();
        FixPath(BlobFileName);
        FullBlobFileName := Magicpath() + '/' + BlobFileName;
        ABSBlobClient.GetBlobAsFile(FullBlobFileName);
        exit(FullBlobFileName);
    end;

    //Replaces File Management - UploadFile
    procedure UploadFile(DialogTitle: Text) BlobFileName: Text
    begin
        BlobFileName := UploadFileWithFilter(DialogTitle, AllFilesFilterTxt);
    end;

    //Replaces File - Upload, File Management - UploadFileWithFilters
    procedure UploadFileWithFilter(DialogTitle: Text; ExtFilter: Text) BlobFileName: Text
    var
        Uploaded: Boolean;
        InStream: InStream;
        ClientFileName: Text;
    begin
        InitializeConnection();

        UploadIntoStream(DialogTitle, '', '', ClientFileName, InStream);
        BlobFileName := FileMgt.GetFileName(ClientFileName);
        Uploaded := SaveBlobFromInStream(BlobFileName, InStream);

        if Uploaded then
            FileMgt.ValidateFileExtension(BlobFileName, ExtFilter);
        if Uploaded then
            exit(BlobFileName);
        exit('');
    end;

    procedure Magicpath(): Text
    begin
        exit('TEMP');   // MAGIC PATH makes sure we don't get a prompt
    end;

    //Replaces File - Download, File Management - DownloadHandler
    procedure DownloadBlobHandler(BlobFileName: Text; ToFileName: Text) Downloaded: Boolean
    var
        FileExt: Text;
        InStream: InStream;
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        InitializeConnection();
        FixPath(BlobFileName);

        ABSOperationResponse := ABSBlobClient.GetBlobAsFile(BlobFileName);
        if ABSOperationResponse.IsSuccessful() then
            Downloaded := true
        else
            Error(ABSOperationResponse.GetError());
    end;

    //Replaces File - Copy, File Management - CopyServerFile
    procedure CopyBlobFile(SourceBlobName: Text; TargetBlobName: Text) Copied: Boolean
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        InitializeConnection();
        FixPath(SourceBlobName);
        FixPath(TargetBlobName);
        FileMgt.IsAllowedPath(SourceBlobName, false);
        FileMgt.IsAllowedPath(TargetBlobName, false);

        ABSOperationResponse := ABSBlobClient.CopyBlob(TargetBlobName, SourceBlobName);
        if ABSOperationResponse.IsSuccessful() then
            Copied := true
        else
            Error(ABSOperationResponse.GetError());
    end;

    //Replaces File - Exists, File Management - ServerFileExists
    procedure BlobFileExists(BlobFileName: Text): Boolean
    begin
        InitializeConnection();
        FixPath(BlobFileName);

        if ABSBlobClient.BlobExists(BlobFileName) then
            exit(true);
        exit(false);
    end;

    //Replaces File - Erase, File Management - DeleteServerFile
    procedure DeleteBlobFile(BlobFileName: Text) Deleted: Boolean
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        InitializeConnection();
        FixPath(BlobFileName);
        FileMgt.IsAllowedPath(BlobFileName, false);
        if not BlobFileExists(BlobFileName) then
            exit(false);

        ABSOperationResponse := ABSBlobClient.DeleteBlob(BlobFileName);
        if ABSOperationResponse.IsSuccessful() then
            Deleted := true
        else
            Error(ABSOperationResponse.GetError());
    end;

    //Replaces File - Rename
    procedure RenameBlob(OldBlobName: Text; NewBlobName: Text) Renamed: Boolean
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
        OldFileName: Text;
        NewFilePath: Text;
    begin
        InitializeConnection();
        FixPath(OldBlobName);
        FixPath(NewBlobName);
        OldFileName := FileMgt.GetFileNameWithoutExtension(FileMgt.GetFileName(OldBlobName));
        NewBlobName := FileMgt.GetFileNameWithoutExtension(NewBlobName);
        ABSOperationResponse := ABSBlobClient.CopyBlob(NewBlobName, OldBlobName);
        if ABSOperationResponse.IsSuccessful() then begin
            ABSBlobClient.DeleteBlob(OldBlobName);
            Renamed := true;
        end else
            Error(ABSOperationResponse.GetError());
    end;

    //Replaces File Management - ServerDirectoryExists
    procedure DirectoryExists(DirectoryName: Text): Boolean
    var
        ABSContent: Record "ABS Container Content";
    begin
        FileMgt.IsAllowedPath(DirectoryName, false);

        InitializeConnection();
        FixPath(DirectoryName);

        ABSBlobClient.ListBlobs(ABSContent);
        if ABSContent.FindSet() then
            ABSContent.SetRange("Full Name", DirectoryName);
        if ABSContent.FindFirst() then
            exit(true)
        else
            exit(false);
    end;

    procedure ContainerExists(ContainerName: Text): Boolean
    var
        ABScontainer: Record "ABS Container" temporary;
    begin
        InitializeConnection();

        ABSBlobContainerClient.ListContainers(ABScontainer);
        if ABScontainer.FindSet() then
            ABScontainer.SetRange(Name, ContainerName);
        if ABScontainer.FindFirst() then
            exit(true)
        else
            exit(false);
    end;

    procedure CreateContainer(ContainerName: Text) Created: Boolean
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        if not ContainerExists(ContainerName) then
            ABSOperationResponse := ABSBlobContainerClient.CreateContainer(ContainerName);
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());
    end;

    //Replaces File Management - RemoveServerDirectory
    // Procedure doesn't have Recursive parameter, because in Azure empty directories can't exist.
    // If Recursive was false operation not needed.
    procedure RemoveDirectory(DirectoryName: text)
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
        ABSContent: Record "ABS Container Content";
    begin
        InitializeConnection();
        FixPath(DirectoryName);

        DirectoryName := DirectoryName.Replace('\', '/');
        if not DirectoryName.EndsWith('/') then
            DirectoryName := DirectoryName + '/';

        FileMgt.IsAllowedPath(DirectoryName, false);
        if DirectoryExists(DirectoryName) then
            ABSBlobClient.ListBlobs(ABSContent);
        ABSContent.SetRange("Parent Directory", DirectoryName);
        ABSOperationResponse := ABSBlobClient.DeleteBlob(ABSContent."Full Name");
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());
    end;

    procedure RemoveContainer(ContainerName: text): Boolean
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        InitializeConnection();

        if ContainerExists(ContainerName) then begin
            ABSOperationResponse := ABSBlobContainerClient.DeleteContainer(ContainerName);
            if ABSOperationResponse.IsSuccessful() then
                exit(true)
            else
                Error(ABSOperationResponse.GetError());
        end
    end;
    //Replaces File Management - GetServerDirectoryFilesList
    procedure GetDirectoryBlobFilesList(var ABSListRec: Record "ABS Connector List")
    begin
        GetDirectoryBlobFilesList(ABSListRec, '');
    end;
    //Replaces File Management - GetServerDirectoryFilesList
    procedure GetDirectoryBlobFilesList(var ABSListRec: Record "ABS Connector List"; DirectoryName: Text)
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
        ABSContent: Record "ABS Container Content";
    begin
        InitializeConnection();
        FixPath(DirectoryName);

        ABSListRec.Reset();
        ABSListRec.DeleteAll();

        ABSOperationResponse := ABSBlobClient.ListBlobs(ABSContent);
        if DirectoryName <> '' then begin
            FileMgt.IsAllowedPath(DirectoryName, false);
            if not DirectoryName.EndsWith('/') then
                DirectoryName := DirectoryName + '/';
            ABSContent.SetRange("Parent Directory", DirectoryName);
        end;
        if ABSContent.FindSet() then
            repeat
                ABSListRec.Init();
                ABSListRec."Blob Type" := ABSContent."Blob Type";
                ABSListRec."Content Length" := ABSContent."Content Length";
                ABSListRec."Content Type" := ABSContent."Content Type";
                ABSListRec."Creation Time" := ABSContent."Creation Time";
                ABSListRec."Full Name" := ABSContent."Full Name";
                ABSListRec."Last Modified" := ABSContent."Last Modified";
                ABSListRec.Level := ABSContent.Level;
                ABSListRec.Name := ABSContent.Name;
                ABSListRec."Parent Directory" := ABSContent."Parent Directory";
                ABSListRec."Resource Type" := ABSContent."Resource Type";
                ABSListRec.URI := ABSContent.URI;
                ABSListRec."XML Value" := ABSContent."XML Value";
                if ABSListRec.Insert(true) then;
            until ABSContent.Next() = 0;
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());

    end;
    //Replaces File Management - GetServerDirectoryFilesListInclSubDirs
    procedure GetDirectoryBlobFilesListInclSubDirs(var ABSListRec: Record "ABS Connector List"; DirectoryName: Text)
    begin
        ABSListRec.Reset();
        ABSListRec.DeleteAll();

        GetDirectoryBlobFilesListInclSubDirsInner(ABSListRec, DirectoryName);
    end;

    //Replaces File Management - GetServerDirectoryFilesListInclSubDirsInner
    local procedure GetDirectoryBlobFilesListInclSubDirsInner(var ABSListRec: Record "ABS Connector List"; DirectoryName: Text)
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
        ABSContent: Record "ABS Container Content";
    begin
        InitializeConnection();
        FixPath(DirectoryName);

        ABSOperationResponse := ABSBlobClient.ListBlobs(ABSContent);
        if DirectoryName <> '' then begin
            FileMgt.IsAllowedPath(DirectoryName, false);
            ABSContent.SetFilter("Parent Directory", '*%1*', DirectoryName);
        end;
        if ABSContent.FindSet() then
            repeat
                ABSListRec.Init();
                ABSListRec."Blob Type" := ABSContent."Blob Type";
                ABSListRec."Content Length" := ABSContent."Content Length";
                ABSListRec."Content Type" := ABSContent."Content Type";
                ABSListRec."Creation Time" := ABSContent."Creation Time";
                ABSListRec."Full Name" := ABSContent."Full Name";
                ABSListRec."Last Modified" := ABSContent."Last Modified";
                ABSListRec.Level := ABSContent.Level;
                ABSListRec.Name := ABSContent.Name;
                ABSListRec."Parent Directory" := ABSContent."Parent Directory";
                ABSListRec."Resource Type" := ABSContent."Resource Type";
                ABSListRec.URI := ABSContent.URI;
                ABSListRec."XML Value" := ABSContent."XML Value";
                if ABSListRec.Insert(true) then;
            until ABSContent.Next() = 0;
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());
    end;
    //Could be used instead File - Close
    //Used locally in UploadFileWithFilters, CreateTempBlobFile, TempBlobFileName
    procedure SaveBlobFromInStream(var BlobFileName: Text; InStream: InStream) Saved: Boolean
    var
        FilePath: Text;
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        InitializeConnection();
        FixPath(BlobFileName);

        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobStream(BlobFileName, InStream);
        if ABSOperationResponse.IsSuccessful() then
            Saved := true
        else
            Error(ABSOperationResponse.GetError());
    end;

    //Could be used instead File - Open
    procedure GetBlob(var TempBlob: Codeunit "Temp Blob"; BlobFileName: Text)
    var
        OutStream: OutStream;
        InStream: InStream;
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        InitializeConnection();
        FixPath(BlobFileName);
        FileMgt.IsAllowedPath(BlobFileName, false);

        if not BlobFileExists(BlobFileName) then
            Error(FileDoesNotExistErr, BlobFileName);

        ABSOperationResponse := ABSBlobClient.GetBlobAsStream(BlobFileName, InStream);
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());

        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
    end;

    //Replaces File Management - BLOBImportFromServerFile
    procedure BLOBImport(var TempBlob: Codeunit "Temp Blob"; BlobFileName: Text)
    var
        OutStream: OutStream;
        InStream: InStream;
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        InitializeConnection();
        FixPath(BlobFileName);
        FileMgt.IsAllowedPath(BlobFileName, false);

        if not BlobFileExists(BlobFileName) then
            Error(FileDoesNotExistErr, BlobFileName);

        ABSOperationResponse := ABSBlobClient.GetBlobAsStream(BlobFileName, InStream);
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());

        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
    end;

    //Replaces File Management - BLOBExportToServerFile
    procedure BLOBExport(var TempBlob: Codeunit "Temp Blob"; BlobFileName: Text)
    var
        InStream: InStream;
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        InitializeConnection();
        FixPath(BlobFileName);
        if BlobFileExists(BlobFileName) then
            Error(Text013, BlobFileName);

        TempBlob.CreateInStream(InStream);

        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobStream(BlobFileName, InStream);
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());
    end;

    //Replaces File Management - InstreamExportToServerFile
    procedure InstreamExport(Instream: InStream; FileExt: Text) BlobFileName: Text
    var
        OutStream: OutStream;
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        InitializeConnection();
        BlobFileName := CopyStr(TempBlobFileName(FileExt), 1, 250);

        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobStream(BlobFileName, Instream);
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());
    end;

    //Replaces File Management - CreateAndWriteToServerFile
    procedure CreateAndWriteToBlobFile(FileContent: Text; FileExt: Text) BlobFileName: Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        Instream: InStream;
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        InitializeConnection();
        BlobFileName := CopyStr(TempBlobFileName(FileExt), 1, 250);

        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(FileContent);
        TempBlob.CreateInStream(Instream);

        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobStream(BlobFileName, Instream);
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());
    end;

    //Replaces File Management - IsClientDirectoryEmpty, IsServerDirectoryEmpty
    procedure IsDirectoryEmpty(DirectoryName: Text): Boolean
    var
        ABSContent: Record "ABS Container Content" temporary;
    begin
        InitializeConnection();
        FixPath(DirectoryName);
        FileMgt.IsAllowedPath(DirectoryName, false);
        if DirectoryExists(DirectoryName) then begin
            ABSBlobClient.ListBlobs(ABSContent);
            exit(ABSContent.Count() = 0);
        end;
        exit(false);
    end;
    //Replaces File Management - GetFileContents
    procedure GetFileContents(BlobFileName: Text) Result: Text
    var
        InStr: InStream;
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        InitializeConnection();
        FixPath(BlobFileName);
        if not BlobFileExists(BlobFileName) then
            exit;

        ABSOperationResponse := ABSBlobClient.GetBlobAsStream(BlobFileName, InStr);
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());

        InStr.Read(Result);
    end;

    local procedure FixPath(Path: Text): Text
    var
        SPPath: Text;
    begin
        SPPath := Path.Replace('\', '/');
        SPPath := SPPath.Replace('//', '/');
        if not SPPath.EndsWith('/') then
            SPPath := SPPath + '/';
        exit(SPPath);
    end;

}