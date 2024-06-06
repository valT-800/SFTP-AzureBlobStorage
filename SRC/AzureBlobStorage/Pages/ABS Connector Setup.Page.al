page 51116 "ABS Connector Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "ABS Connector Setup";
    Caption = 'Azure Blob Storage Connector Setup';
    ModifyAllowed = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Setup)
            {
                field("Account Name"; Rec."Account Name")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        ABSFileManagement.ChangeConnectionValues(Rec."Account Name", Rec."Container Name", Rec."Shared Key");
                    end;
                }
                field("Container Name"; Rec."Container Name")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        ABSFileManagement.ChangeConnectionValues(Rec."Account Name", Rec."Container Name", Rec."Shared Key");
                    end;
                }
                field("Shared Key"; Rec."Shared Key")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                    trigger OnValidate()
                    begin
                        ABSFileManagement.ChangeConnectionValues(Rec."Account Name", Rec."Container Name", Rec."Shared Key");
                    end;
                }
            }
            group(File)
            {
                field(BlobName; BlobName)
                {
                    ApplicationArea = All;
                    Caption = 'Blob Name';
                }

                field(DirectoryName; DirectoryName)
                {
                    ApplicationArea = All;
                    Caption = 'Directory Name';
                }
                field(BlobContents; BlobContents)
                {
                    ApplicationArea = All;
                    Caption = 'Blob Contents';
                    MultiLine = true;
                }
            }
            part(ABSList; "ABS Connector List")
            {
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Connect)
            {
                ApplicationArea = All;
                Caption = 'Connect to a Azure Blob Storage';

                trigger OnAction()
                begin
                    ABSFileManagement.InitializeConnection(Rec."Account Name", Rec."Container Name", Rec."Shared Key");
                end;
            }
            action(ListContainers)
            {
                ApplicationArea = All;
                Caption = 'List Containers';
                trigger OnAction()
                var
                    ABSListRec: Record "ABS Connector List";
                begin
                    ABSListRec.DeleteAll();

                    ABSFileManagement.GetContainersList(ABSListRec);
                    CurrPage.ABSList.Page.Update(); //Update the current page to refresh the list
                end;
            }
            action(ShowDirectory)
            {
                ApplicationArea = All;
                Caption = 'Show Directory';
                trigger OnAction()
                var
                    ABSListRec: Record "ABS Connector List";
                begin
                    ABSFileManagement.GetDirectoryBlobFilesList(ABSListRec, DirectoryName);
                    CurrPage.ABSList.Page.Update(); //Update the current page to refresh the list
                end;
            }
            action(CreateContainer)
            {
                ApplicationArea = All;
                Caption = 'Create Container';
                trigger OnAction()
                var
                    ABSListRec: Record "ABS Connector List";
                begin
                    ABSFileManagement.CreateContainer(Rec."Container Name");
                end;
            }
            action(UploadFile)
            {
                ApplicationArea = All;
                Caption = 'Upload File to Blob';

                trigger OnAction()
                var
                    BlobName: Text;
                    InStream: InStream;
                begin
                    BlobName := ABSFileManagement.UploadFile('');
                    if not (BlobName = '') then
                        Message('File uploaded');
                end;
            }
            action(CreateFile)
            {
                ApplicationArea = All;
                Caption = 'Create File';

                trigger OnAction()
                var
                    InStream: InStream;
                    OutStream: OutStream;
                    TempBlob: Codeunit "Temp Blob";
                begin
                    TempBlob.CreateOutStream(OutStream);
                    OutStream.Write(BlobContents);
                    TempBlob.CreateInStream(InStream);
                    ABSFileManagement.SaveBlobFromInStream(BlobName, InStream);
                end;
            }
            action(CreateTempFile)
            {
                ApplicationArea = All;
                Caption = 'Create Temporary File';

                trigger OnAction()
                var
                    InStream: InStream;
                    OutStream: OutStream;
                    TempBlob: Codeunit "Temp Blob";
                begin
                    TempBlob.CreateOutStream(OutStream);
                    OutStream.Write(BlobContents);
                    TempBlob.CreateInStream(InStream);
                    ABSFileManagement.CreateTempBlobFile();
                end;
            }
            action(GetFileContent)
            {
                ApplicationArea = All;
                Caption = 'Get File Content';

                trigger OnAction()
                var
                    InStream: InStream;
                    OutStream: OutStream;
                    TempBlob: Codeunit "Temp Blob";
                    ABSListRec: Record "ABS Connector List";
                begin
                    CurrPage.ABSList.Page.GetRecord(ABSListRec);

                    ABSFileManagement.GetBlob(TempBlob, ABSListRec."Full Name");
                    TempBlob.CreateInStream(InStream);
                    InStream.Read(BlobContents);
                end;
            }
            action(ReplaceFileContent)
            {
                ApplicationArea = All;
                Caption = 'Replace Selected File Content';

                trigger OnAction()
                var
                    InStream: InStream;
                    OutStream: OutStream;
                    TempBlob: Codeunit "Temp Blob";
                    ABSListRec: Record "ABS Connector List";
                begin
                    CurrPage.ABSList.Page.GetRecord(ABSListRec);

                    TempBlob.CreateOutStream(OutStream);
                    OutStream.Write(BlobContents);
                    TempBlob.CreateInStream(InStream);
                    ABSFileManagement.SaveBlobFromInStream(ABSListRec."Full Name", InStream);
                end;
            }
            action(DownloadBlob)
            {
                ApplicationArea = All;
                Caption = 'Download Selected Blob';

                trigger OnAction()
                var
                    ABSListRec: Record "ABS Connector List";
                    FileName: Text;
                begin
                    CurrPage.ABSList.Page.GetRecord(ABSListRec);
                    ABSFileManagement.DownloadBlobHandler(ABSListRec.Name, BlobName);
                end;
            }
            action(DeleteBlob)
            {
                ApplicationArea = All;
                Caption = 'Delete Blob';

                trigger OnAction()
                var
                    ABSListRec: Record "ABS Connector List";
                begin
                    CurrPage.ABSList.Page.GetRecord(ABSListRec);
                    if ABSFileManagement.DeleteBlobFile(ABSListRec."Full Name") then
                        Message('Blob succesfully deleted');
                end;
            }
            action(DeleteDirectory)
            {
                ApplicationArea = All;
                Caption = 'Delete Selected Directory';

                trigger OnAction()
                var
                    ABSListRec: Record "ABS Connector List";
                begin
                    CurrPage.ABSList.Page.GetRecord(ABSListRec);
                    ABSFileManagement.RemoveDirectory(ABSListRec."Full Name");
                    if not ABSFileManagement.DirectoryExists(ABSListRec."Full Name") then
                        Message('Directory succesfully deleted');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    var
        BlobName: Text;
        DirectoryName: Text;
        BlobContents: Text;
        ABSFileManagement: Codeunit "ABS File Management";
        FileMgt: Codeunit "File Management";

}