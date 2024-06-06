table 51114 "SFTP con WinSCP"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Username"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Password"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "SFTP Address"; Text[250])
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