tableextension 50100 "Ditech_PurchRcptHeader" extends "Purch. Rcpt. Header"
{
    fields
    {
        field(50100; "Ditech_Invoway Timbrado"; Boolean)
        {
            Caption = 'Invoway Timbrado';
            DataClassification = CustomerContent;
        }
        field(50101; "Ditech_Invoway Error"; Text[500])
        {
            Caption = 'Invoway Error';
            DataClassification = CustomerContent;
        }
    }
}
