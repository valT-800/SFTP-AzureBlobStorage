codeunit 50010 "SFTP con WinSCP"
{
    // -001 08/10/18 edaimiel - Creación.
    //      Utilidades para usar SFTP (Secure FTP) con la dll de WinSCP.
    //      No compilará si no existe la dll WinSCPnet.dll en la carpeta de Addins. Aquí se usa la versión 1.5.3.8172
    //      La dll se obtiene en https://winscp.net/eng/download.php
    //      Se instala el programa y se recupera la dll y los otros ejecutables de "C:\Program Files (x86)\WinSCP"
    //      Los archivos WinSCPnet.dll y WinSCP.exe se han de copiar a la carpeta Addins. (mejor crear una subcarpeta WinSCP con esos 3 archivos).
    //      En https://winscp.net/eng/docs/library hay ayuda y documentación.
    // -002 19/12/22 edaimiel - Copiado desde Vimbodi y desde GMFuel (extensión SFTP with WinSCP).
    // -003 12/04/22 edaimiel - Añadir Session.Dispose en todas las funciones que usen una variable Session local. Sin comentar en el código.


    trigger OnRun()
    begin
    end;

    var
        // SPLN1.00 - Start
        //    SessionOptions: DotNet SessionOptions;
        HttpClient: HttpClient;
        AzureFuncSetup: Record "Azure Function Connector Setup";
    // SPLN1.00 - End

    [TryFunction]
    procedure InitSessionOptions(Host: Text; User: Text; Password: Text; PortNumber: Integer; SshHostKeyFingerprint: Text)
    var
        // SPLN1.00 - Start
        // Protocol: DotNet Protocol;
        httpContent: HttpContent;
        jsonBody: text;
        httpResponse: HttpResponseMessage;
        httpHeader: HttpHeaders;
        response: Text;
        jsonObject: JsonObject;
        uri: Text;
    // SPLN1.00 - End
    begin
        // SPLN1.00 - Start
        // CLEAR(SessionOptions);
        // SessionOptions := SessionOptions.SessionOptions();
        // SessionOptions.Protocol := Protocol.Sftp;
        // SessionOptions.Timeout := 15000;  //15 seconds. Default Value.
        // SessionOptions.HostName := Host;
        // SessionOptions.UserName := User;
        // SessionOptions.Password := Password;
        // IF PortNumber <> 0 THEN
        //     SessionOptions.PortNumber := PortNumber;
        // SessionOptions.SshHostKeyFingerprint := SshHostKeyFingerprint;

        AzureFuncSetup.Get();
        jsonObject.Add('address', Host);
        jsonObject.Add('port', PortNumber);
        jsonObject.Add('username', User);
        jsonObject.Add('password', Password);
        jsonObject.WriteTo(jsonBody);
        httpContent.WriteFrom(jsonBody);
        httpContent.GetHeaders(httpHeader);
        httpHeader.Remove('Content-Type');
        httpHeader.Add('Content-Type', 'application/json');
        HttpClient.SetBaseAddress(AzureFuncSetup."Base Url");
        uri := StrSubstNo('SFTPInitializeConnection?code=%1', AzureFuncSetup."Function Key");
        HttpClient.Put(uri, httpContent, httpResponse);
        if not httpResponse.IsSuccessStatusCode then begin
            httpResponse.Content.ReadAs(response);
            Error('%1 %2. %3', httpResponse.HttpStatusCode, httpResponse.ReasonPhrase, response);
        end;
        // SPLN1.00 - End
    end;


    procedure CopyFolder(SourcePath: Text; DestinationPath: Text; IncludeSubFolders: Boolean)
    var
        // SPLN1.00 - Start
        // DirectoryInfo: DotNet DirectoryInfo;
        // FileAttributes: DotNet FileAttributes;
        // FileInfo: DotNet FileInfo;
        // ArrayFileInfo: DotNet Array;
        // RemotePath: DotNet RemotePath;
        // SearchOption: DotNet SearchOption;
        // Session: DotNet Session;
        // TransferMode: DotNet TransferMode;
        // TransferOperationResult: DotNet TransferOperationResult;
        // TransferOptions: DotNet TransferOptions; 
        // i: Integer;
        // RemoteFilePath: Text;
        httpContent: HttpContent;
        jsonBody: text;
        httpResponse: HttpResponseMessage;
        httpHeader: HttpHeaders;
        response: Text;
        jsonObject: JsonObject;
        uri: Text;
    // SPLN1.00 - End
    begin
        CheckSessionOptions();

        // SPLN1.00 - Start
        // Session := Session.Session();
        // Session.Open(SessionOptions);
        // 
        // IF IncludeSubFolders THEN
        //     SearchOption := SearchOption.AllDirectories
        // ELSE
        //     SearchOption := SearchOption.TopDirectoryOnly;
        // 
        // DirectoryInfo := DirectoryInfo.DirectoryInfo(SourcePath);
        // ArrayFileInfo := DirectoryInfo.GetFileSystemInfos('*', SearchOption);
        // FOR i := 0 TO (ArrayFileInfo.Length - 1) DO BEGIN
        //     FileInfo := ArrayFileInfo.GetValue(i);
        //     RemoteFilePath := RemotePath.TranslateLocalPathToRemote(FileInfo.FullName, SourcePath, DestinationPath);
        // 
        //     IF FileInfo.Attributes.HasFlag(FileAttributes.Directory) THEN BEGIN
        //         IF NOT Session.FileExists(RemoteFilePath) THEN
        //             Session.CreateDirectory(RemoteFilePath);
        //     END ELSE BEGIN
        //         TransferOptions := TransferOptions.TransferOptions();
        //         TransferOptions.TransferMode := TransferMode.Binary;
        //         TransferOperationResult := Session.PutFiles(FileInfo.FullName, RemoteFilePath, FALSE, TransferOptions);
        //         TransferOperationResult.Check();
        //     END;
        // END;
        // 
        // Session.Dispose();
        uri := StrSubstNo('SFTPCopyDirectoryFromAzure?code=%1', AzureFuncSetup."Function Key");
        jsonObject.Add('azurePath', SourcePath);
        jsonObject.Add('sftpPath', DestinationPath);
        jsonObject.Add('includeSubDirectories', IncludeSubFolders);
        jsonObject.WriteTo(jsonBody);
        httpContent.WriteFrom(jsonBody);
        httpContent.GetHeaders(httpHeader);
        httpHeader.Remove('Content-Type');
        httpHeader.Add('Content-Type', 'application/json');
        HttpClient.Post(uri, httpContent, httpResponse);
        if not httpResponse.IsSuccessStatusCode then begin
            httpResponse.Content.ReadAs(response);
            Error('%1 %2. %3', httpResponse.HttpStatusCode, httpResponse.ReasonPhrase, response);
        end;
        // SPLN1.00 - End
    end;

    [TryFunction]
    procedure UploadFile(SourceFile: Text; DestinationUrl: Text)
    var
        // Session: DotNet Session;
        // TransferMode: DotNet TransferMode;
        // TransferOperationResult: DotNet TransferOperationResult;
        // TransferOptions: DotNet TransferOptions;
        httpContent: HttpContent;
        jsonBody: text;
        httpResponse: HttpResponseMessage;
        httpHeader: HttpHeaders;
        response: Text;
        jsonObject: JsonObject;
        uri: Text;
    // SPLN1.00 - End
    begin
        //CheckSessionOptions();
        // SPLN1.00 - Start
        // Session := Session.Session();
        // //Session.SessionLogPath := 'your log path';
        // Session.Open(SessionOptions);
        // 
        // TransferOptions := TransferOptions.TransferOptions();
        // TransferOptions.TransferMode := TransferMode.Binary;
        // TransferOperationResult := Session.PutFiles(SourceFile, DestinationUrl, FALSE, TransferOptions); // DestinationUrl similar a "/Vimbodi/Qv_Tely/"
        // TransferOperationResult.Check(); //Throw on any error
        // 
        // Session.Dispose();
        uri := StrSubstNo('SFTPUploadFileFromAzure?code=%1', AzureFuncSetup."Function Key");
        jsonObject.Add('azureFilePath', SourceFile);
        jsonObject.Add('sftpPath', DestinationUrl);
        jsonObject.WriteTo(jsonBody);
        httpContent.WriteFrom(jsonBody);
        httpContent.GetHeaders(httpHeader);
        httpHeader.Remove('Content-Type');
        httpHeader.Add('Content-Type', 'application/json');
        HttpClient.Post(uri, httpContent, httpResponse);
        if not httpResponse.IsSuccessStatusCode then begin
            httpResponse.Content.ReadAs(response);
            Error('%1 %2. %3', httpResponse.HttpStatusCode, httpResponse.ReasonPhrase, response);
        end;
        // SPLN1.00 - End
    end;

    [TryFunction]
    procedure UploadFiles(Filenames: List of [Text]; DestinationUrl: Text)
    var
        // SPLN1.00 - Start
        // i: Integer;
        // Session: DotNet Session;
        // TransferMode: DotNet TransferMode;
        // TransferOperationResult: DotNet TransferOperationResult;
        // TransferOptions: DotNet TransferOptions;
        httpContent: HttpContent;
        jsonBody: text;
        httpResponse: HttpResponseMessage;
        httpHeader: HttpHeaders;
        response: Text;
        file: Text;
        jsonObject: JsonObject;
        uri: Text;
    // SPLN1.00 - End
    begin
        CheckSessionOptions();

        // SPLN1.00 - Start
        // Session := Session.Session();
        // Session.Open(SessionOptions);
        // 
        // TransferOptions := TransferOptions.TransferOptions();
        // TransferOptions.TransferMode := TransferMode.Binary;
        // FOR i := 0 TO Filenames.Count - 1 DO BEGIN
        //     TransferOperationResult := Session.PutFiles(Filenames.Item(i), DestinationUrl, FALSE, TransferOptions);
        //     TransferOperationResult.Check(); //Throw on any error
        // END;
        // 
        // Session.Dispose();
        uri := StrSubstNo('SFTPUploadFileFromAzure?code=%1', AzureFuncSetup."Function Key");
        foreach file in Filenames do begin
            jsonObject.Remove('sftpPath');
            jsonObject.Remove('azureFilePath');
            jsonObject.Add('sftpPath', DestinationUrl);
            jsonObject.Add('azureFilePath', file);
            jsonObject.WriteTo(jsonBody);
            httpContent.WriteFrom(jsonBody);
            httpContent.GetHeaders(httpHeader);
            httpHeader.Remove('Content-Type');
            httpHeader.Add('Content-Type', 'application/json');
            HttpClient.Post(uri, httpContent, httpResponse);
            if not httpResponse.IsSuccessStatusCode then begin
                httpResponse.Content.ReadAs(response);
                Error('%1 %2. %3', httpResponse.HttpStatusCode, httpResponse.ReasonPhrase, response);
            end;
        end;
        // SPLN1.00 - End

    end;

    [TryFunction]

    procedure ListDirectory(Url: Text; Filenames: List of [Text]; IncludeDirectories: Boolean)
    var
        // SPLN1.00 - Start
        // RemoteDirectoryInfo: DotNet RemoteDirectoryInfo;
        // RemoteFileInfo: DotNet RemoteFileInfo;
        // RemoteFileInfoCollection: DotNet RemoteFileInfoCollection;
        // Session: DotNet Session;
        //i: Integer;
        jsonText: text;
        httpResponse: HttpResponseMessage;
        JsonArray: JsonArray;
        ParamToken: JsonToken;
        name: text;
        uri: Text;
    // SPLN1.00 - End
    begin
        CheckSessionOptions();

        // SPLN1.00 - Start
        // Session := Session.Session();
        // Session.Open(SessionOptions);
        // 
        // RemoteDirectoryInfo := Session.ListDirectory(Url);
        // RemoteFileInfoCollection := RemoteDirectoryInfo.Files;
        // IF RemoteFileInfoCollection.Count > 0 THEN BEGIN
        //     IF ISNULL(Filenames) THEN
        //         Filenames := Filenames.StringCollection();
        //     FOR i := 0 TO RemoteFileInfoCollection.Count - 1 DO BEGIN
        //         RemoteFileInfo := RemoteFileInfoCollection.Item(i);
        //         IF (NOT RemoteFileInfo.IsParentDirectory) AND (NOT RemoteFileInfo.IsThisDirectory) AND
        //            (IncludeDirectories OR (NOT RemoteFileInfo.IsDirectory)) THEN BEGIN
        //             Filenames.Add(RemoteFileInfo.Name);
        //         END;
        //     END; //FOR
        // END;
        // 
        // Session.Dispose();

        uri := StrSubstNo('SFTPListDirectory?code=%1&sftpPath=%2&includeDirectories=%3', AzureFuncSetup."Function Key", Url, IncludeDirectories);
        HttpClient.Get(uri, httpResponse);
        httpResponse.Content.ReadAs(jsonText);
        if httpResponse.IsSuccessStatusCode then begin
            JsonArray.ReadFrom(jsonText);
            foreach ParamToken in JsonArray do begin
                ParamToken.AsValue().WriteTo(name);
                Filenames.Add(name);
            end;
        end
        else
            Error('%1 %2. %3', httpResponse.HttpStatusCode, httpResponse.ReasonPhrase, jsonText);
        // SPLN1.00 - End
    end;

    //Replaces File Management - GetServerDirectoryFilesList
    procedure GetDirectoryFilesList(Url: Text; var SFTPConnectorList: Record "SFTP Connector List"; IncludeDirectories: Boolean)
    var
        response: text;
        httpResponse: HttpResponseMessage;
        JsonArray: JsonArray;
        ParamToken: JsonToken;
        JsonObject: JsonObject;
        uri: Text;
    begin
        CheckSessionOptions();

        SFTPConnectorList.Reset();
        SFTPConnectorList.DeleteAll();

        uri := StrSubstNo('SFTPListDirectoryFiles?code=%1&sftpPath=%2&includeDirectories=%3', AzureFuncSetup."Function Key", Url, IncludeDirectories);
        HttpClient.Get(uri, httpResponse);
        httpResponse.Content.ReadAs(response);
        if httpResponse.IsSuccessStatusCode then begin
            JsonArray.ReadFrom(response);
            foreach ParamToken in JsonArray do begin
                JsonObject := ParamToken.AsObject();
                SFTPConnectorList.Init();
                SFTPConnectorList.Title := ValidateJsonToken(JsonObject, 'Name').AsValue().AsText();
                SFTPConnectorList.Path := ValidateJsonToken(JsonObject, 'FullName').AsValue().AsText();
                SFTPConnectorList.Insert(true);
            end;
        end else
            Error('%1 %2. %3', httpResponse.HttpStatusCode, httpResponse.ReasonPhrase, response);
    end;

    local procedure ValidateJsonToken(JsonObject: JsonObject; TokenKey: text) JsonToken: JsonToken
    begin
        if not JsonObject.Get(TokenKey, JsonToken) then
            Error('Could not find token with key: %1', TokenKey);
    end;

    [TryFunction]

    procedure DownloadFiles(Url: Text; WildCard: Text; DestinationFolder: Text; Remove: Boolean)
    var
        // SPLN1.00 - Start
        //     Session: DotNet Session;
        //     TransferMode: DotNet TransferMode;
        //     TransferOperationResult: DotNet TransferOperationResult;
        //     TransferOptions: DotNet TransferOptions;
        httpContent: HttpContent;
        jsonBody: Text;
        response: text;
        httpResponse: HttpResponseMessage;
        httpHeader: HttpHeaders;
        jsonObject: JsonObject;
        uri: Text;
    // SPLN1.00 - End
    begin
        CheckSessionOptions();

        IF WildCard <> '' THEN BEGIN
            IF Url = '' THEN
                Url := '/';
            IF COPYSTR(Url, STRLEN(Url), 1) <> '/' THEN
                Url := Url + '/';
            Url := Url + WildCard;
            IF COPYSTR(DestinationFolder, STRLEN(DestinationFolder), 1) <> '\' THEN
                DestinationFolder := DestinationFolder + '\';
        END;
        // SPLN1.00 - Start
        // Session := Session.Session();
        // Session.Open(SessionOptions);
        // 
        // TransferOptions := TransferOptions.TransferOptions();
        // TransferOptions.TransferMode := TransferMode.Binary;
        // TransferOperationResult := Session.GetFiles(Url, DestinationFolder, Remove, TransferOptions);
        // TransferOperationResult.Check(); //Throw on any error
        // 
        // Session.Dispose();

        uri := StrSubstNo('SFTPDownloadFilesToAzure?code=%1', AzureFuncSetup."Function Key");
        jsonObject.Add('sftpPath', Url);
        jsonObject.Add('azurePath', DestinationFolder);
        jsonObject.Add('remove', Remove);
        jsonObject.WriteTo(jsonBody);
        httpContent.WriteFrom(jsonBody);
        httpContent.GetHeaders(httpHeader);
        httpHeader.Remove('Content-Type');
        httpHeader.Add('Content-Type', 'application/json');
        HttpClient.Post(uri, httpContent, httpResponse);
        if not httpResponse.IsSuccessStatusCode then begin
            httpResponse.Content.ReadAs(response);
            Error('%1 %2. %3', httpResponse.HttpStatusCode, httpResponse.ReasonPhrase, response);
        end;
    end;

    [TryFunction]

    procedure DownloadFile(Url: Text; WildCard: Text; DestinationFolder: Text; Remove: Boolean)
    var
        httpContent: HttpContent;
        jsonBody: Text;
        response: text;
        httpResponse: HttpResponseMessage;
        httpHeader: HttpHeaders;
        jsonObject: JsonObject;
        uri: Text;
    begin
        CheckSessionOptions();

        IF WildCard <> '' THEN BEGIN
            IF Url = '' THEN
                Url := '/';
            IF COPYSTR(Url, STRLEN(Url), 1) <> '/' THEN
                Url := Url + '/';
            Url := Url + WildCard;
            IF COPYSTR(DestinationFolder, STRLEN(DestinationFolder), 1) <> '/' THEN
                DestinationFolder := DestinationFolder + '/';
        END;

        uri := StrSubstNo('SFTPDownloadFile?code=%1', AzureFuncSetup."Function Key");

        jsonObject.Add('sftpFilePath', Url);
        jsonObject.Add('azurePath', DestinationFolder);
        jsonObject.Add('remove', Remove);
        jsonObject.WriteTo(jsonBody);

        httpContent.WriteFrom(jsonBody);
        httpContent.GetHeaders(httpHeader);
        httpHeader.Remove('Content-Type');
        httpHeader.Add('Content-Type', 'application/json');
        HttpClient.Post(uri, httpContent, httpResponse);
        if not httpResponse.IsSuccessStatusCode then begin
            httpResponse.Content.ReadAs(response);
            Error('%1 %2. %3', httpResponse.HttpStatusCode, httpResponse.ReasonPhrase, response);
        end;
        // SPLN1.00 - End
    end;

    [TryFunction]

    procedure RemoveFiles(Url: Text)
    var
        // SPLN1.00 - Start
        // Session: DotNet Session;
        // RemovalOperationResult: DotNet RemovalOperationResult;
        response: text;
        httpResponse: HttpResponseMessage;
        uri: Text;
    // SPLN1.00 - End
    begin

        CheckSessionOptions();
        // SPLN1.00 - Start
        // Session := Session.Session();
        // Session.Open(SessionOptions);
        // 
        // RemovalOperationResult := Session.RemoveFiles(Url);
        // RemovalOperationResult.Check(); //Throw on any error
        // 
        // Session.Dispose();

        uri := StrSubstNo('SFTPDeleteFiles?code=%1&sftpPath=%2', AzureFuncSetup."Function Key", Url);
        HttpClient.Delete(uri, httpResponse);
        if not httpResponse.IsSuccessStatusCode then begin
            httpResponse.Content.ReadAs(response);
            Error('%1 %2. %3', httpResponse.HttpStatusCode, httpResponse.ReasonPhrase, response);
        end;
        // SPLN1.00 - End

    end;

    [TryFunction]

    procedure RemoveFile(Url: Text)
    var
        response: text;
        httpResponse: HttpResponseMessage;
        uri: Text;
    begin
        CheckSessionOptions();

        uri := StrSubstNo('SFTPDeleteFile?code=%1&sftpFilePath=%2', AzureFuncSetup."Function Key", Url);
        HttpClient.Delete(uri, httpResponse);
        if not httpResponse.IsSuccessStatusCode then begin
            httpResponse.Content.ReadAs(response);
            Error('%1 %2. %3', httpResponse.HttpStatusCode, httpResponse.ReasonPhrase, response);
        end;
        // SPLN1.00 - End

    end;

    local procedure CheckSessionOptions()
    var
        TXT_NOT_INITIALIZED: Label 'This is a programming error: The codeunit has not been properly initialized. Call the InitSessionOptions function first.';
        // SPLN1.00 - Start
        httpResponse: HttpResponseMessage;
        uri: Text;
    // SPLN1.00 - End
    begin
        // SPLN1.00 - Start
        // IF ISNULL(SessionOptions) THEN
        uri := 'SFTPCheckConnection?code=' + AzureFuncSetup."Function Key";
        HttpClient.Get(uri, httpResponse);
        if not httpResponse.IsSuccessStatusCode then
            // SPLN1.00 - End
            ERROR(TXT_NOT_INITIALIZED);
    end;
}

