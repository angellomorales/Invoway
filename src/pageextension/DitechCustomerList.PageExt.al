pageextension 50100 "Ditech_CustomerList" extends "Customer List"
{
    actions
    {
        addafter("C&ontact_Promoted")
        {
            actionref(Ditech_TestXML_Promoted; Ditech_TestXML)
            {

            }
        }
        addafter("&Customer")
        {
            action(Ditech_TestXML)
            {
                ApplicationArea = All;
                ToolTip = 'Test xml export';
                Image = Export;
                trigger OnAction()
                var
                    MessageMgt: Codeunit Ditech_MessageMgt;
                begin
                    MessageMgt.EntradaMercancia(Rec);
                end;
            }
        }
    }
}
