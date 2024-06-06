page 51113 "SFTP Connector Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "SFTP con WinSCP";
    ModifyAllowed = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Setup)
            {
                field("SFTP Address"; Rec."SFTP Address")
                {
                    ApplicationArea = All;
                }
                field(Username; Rec.Username)
                {
                    ApplicationArea = All;
                }
                field(Password; Rec.Password)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
            }
            group(SFTPFile)
            {
                Caption = 'SFTP file';
                field(SFTPFileName; SFTPFileName)
                {
                    ApplicationArea = All;
                    Caption = 'SFTP File Name';
                }
                field(SFTPFileContents; SFTPFileContents)
                {
                    ApplicationArea = All;
                    Caption = 'SFTP File Contents';
                    MultiLine = true;
                }
                field(SFTPDirectoryPath; SFTPDirectoryPath)
                {
                    ApplicationArea = All;
                    Caption = 'SFTP Directory Path';
                }
            }
            group(AzureFile)
            {
                Caption = 'Azure file';
                field(AzureFileName; AzureFileName)
                {
                    ApplicationArea = All;
                    Caption = 'Azure File Name';
                }
                field(AzureDirectoryPath; AzureDirectoryPath)
                {
                    ApplicationArea = All;
                    Caption = 'Azure Directory Path';
                }
            }
            part(SFTPList; "SFTP Connector List")
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
                Caption = 'Connect to a server';

                trigger OnAction()
                begin
                    SFTP.InitSessionOptions(Rec."SFTP Address", Rec.Username, Rec.Password, 22, '');
                end;
            }
            action(ShowDirectory)
            {
                ApplicationArea = All;
                Caption = 'Show Directory';
                trigger OnAction()
                var
                    SFTPListRec: Record "SFTP Connector List";
                begin
                    SFTPListRec.Reset();
                    SFTPListRec.DeleteAll();

                    SFTP.GetDirectoryFilesList(SFTPDirectoryPath, SFTPListRec, true);

                    CurrPage.SFTPList.Page.Update(); //Update the current page to refresh the list
                end;
            }
            action(UploadFile)
            {
                ApplicationArea = All;
                Caption = 'Upload File from Azure';

                trigger OnAction()
                begin
                    SFTP.UploadFile(AzureFileName, SFTPDirectoryPath);
                end;
            }
            action(CopyDirectory)
            {
                ApplicationArea = All;
                Caption = 'Copy Directory from Azure';

                trigger OnAction()
                begin
                    SFTP.CopyFolder(AzureDirectoryPath, SFTPDirectoryPath, true);
                end;
            }
            action(DownloadFilesToAzure)
            {
                ApplicationArea = All;
                Caption = 'Download Directory Files To Azure';

                trigger OnAction()
                begin
                    SFTP.DownloadFiles(SFTPDirectoryPath, '', AzureDirectoryPath, false);
                end;
            }
            action(DownloadFile)
            {
                ApplicationArea = All;
                Caption = 'Download File to Azure';

                trigger OnAction()
                var
                    recSFTPList: Record "SFTP Connector List";
                begin
                    CurrPage.SFTPList.Page.GetRecord(recSFTPList);

                    if SFTP.DownloadFile(recSFTPList.Path, '', AzureDirectoryPath, false) then
                        Message('File downloaded to Azure Blob Storage');
                end;
            }
            action(DeleteFile)
            {
                ApplicationArea = All;
                Caption = 'Delete File';

                trigger OnAction()
                var
                    recSFTPList: Record "SFTP Connector List";
                begin
                    CurrPage.SFTPList.Page.GetRecord(recSFTPList);
                    SFTP.RemoveFile(recSFTPList.Path);
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

    trigger OnAfterGetRecord()
    begin
        SFTPDirectoryPath := '/C:/Users/ValentinaO/Documents/sftp';
    end;

    var
        SFTPFileName: Text;
        SFTPFileContents: Text;
        SFTPDirectoryPath: Text;
        AzureFileName: Text;
        AzureDirectoryPath: Text;
        SFTP: Codeunit "SFTP con WinSCP";
        RootFolderPath: Text;
        FileMgt: Codeunit "File Management";

}