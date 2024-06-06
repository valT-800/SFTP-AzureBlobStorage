page 51115 "ABS Connector List"
{
    PageType = ListPart;
    SourceTable = "ABS Connector List";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = All;
                }
                field("Parent Directory"; Rec."Parent Directory")
                {
                    ApplicationArea = All;
                }
                field("Blob Type"; Rec."Blob Type")
                {
                    ApplicationArea = All;
                }
                field("Resource Type"; Rec."Resource Type")
                {
                    ApplicationArea = All;
                }
                field("Content Type"; Rec."Content Type")
                {
                    ApplicationArea = All;
                }
                field("Content Length"; Rec."Content Length")
                {
                    ApplicationArea = All;
                }
                field("Creation Time"; Rec."Creation Time")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
    end;
}