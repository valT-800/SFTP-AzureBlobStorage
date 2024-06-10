table 51116 "ABS Connector Setup"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Account Name"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(3; "Shared Key"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Container Name"; Text[250])
        {
            DataClassification = ToBeClassified;
        }

    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}