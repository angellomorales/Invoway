codeunit 50101 "Ditech_SubscriptionMgt"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure OnAfterPostPurchaseDoc(PurchRcpHdrNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        MessageMgt: Codeunit Ditech_MessageMgt;

    begin

        if PurchRcpHdrNo <> '' then
            if PurchRcptHeader.Get(PurchRcpHdrNo) then
                if not PurchRcptHeader."Ditech_Invoway Timbrado" then
                    MessageMgt.EntradaMercancia(PurchRcptHeader);
    end;
}
