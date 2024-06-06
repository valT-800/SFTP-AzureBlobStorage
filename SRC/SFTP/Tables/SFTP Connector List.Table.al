table 51113 "SFTP Connector List"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            Caption = 'Id';
        }

        field(2; Title; Text[250])
        {
            Caption = 'Title';
        }

        field(5; "Path"; Text[2048])
        {
            Caption = 'Path';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    begin
        if not xRec.IsEmpty() then
            Rec.Id := xRec.Id + 1;
    end;
}