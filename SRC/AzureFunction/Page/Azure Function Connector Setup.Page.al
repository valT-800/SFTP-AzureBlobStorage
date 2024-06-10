page 51117 "Azure Function Connector Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Azure Function Connector Setup";
    Caption = 'Azure Function Connector Setup';
    ModifyAllowed = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Setup)
            {
                field("Base Url"; Rec."Base Url")
                {
                    ApplicationArea = All;
                }
                field("Function Key"; Rec."Function Key")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Test)
            {
                ApplicationArea = All;
                Caption = 'Test function';

                trigger OnAction()
                var
                    httpClient: HttpClient;
                    httpResponse: HttpResponseMessage;
                    result: Text;
                begin
                    httpClient.Get(Rec."Base Url" + 'Test?code=' + Rec."Function Key", httpResponse);
                    httpResponse.Content.ReadAs(result);
                    if httpResponse.IsSuccessStatusCode() then
                        Message(result)
                    else begin
                        Error('%1 %2. %3', httpResponse.HttpStatusCode(), httpResponse.ReasonPhrase, result);
                    end;
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
}