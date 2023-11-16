pageextension 50100 "Ditech_PostedPurchaseReceipts" extends "Posted Purchase Receipts"
{
    layout
    {
        addafter("No. Printed")
        {
            field("Ditech_Invoway Timbrado"; Rec."Ditech_Invoway Timbrado")
            {
                ToolTip = 'Indica si el documento esta timbrado en Invoway';
                Editable = true;
            }
            field("Ditech_Invoway Error"; Rec."Ditech_Invoway Error")
            {
                ToolTip = 'Indica el error al timbrar';
            }
        }
    }
    actions
    {
        addafter(Dimensions_Promoted)
        {
            actionref(Ditech_TimbradoManual_Promoted; Ditech_TimbradoManual)
            {

            }
        }
        addafter(Dimensions)
        {
            action(Ditech_TimbradoManual)
            {
                ApplicationArea = All;
                Caption = 'Timbrado Manual';
                ;
                ToolTip = 'Ejecuta el timbrado manual con Invoway';
                Visible = not Rec."Ditech_Invoway Timbrado";
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
