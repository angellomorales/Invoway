codeunit 50100 "Ditech_MessageMgt"
{

    procedure EntradaMercancia(var PurchRcptHeader: record "Purch. Rcpt. Header")
    var
        Url: Text;
        SoapAction: Text;
        ActionName: Text;
        ActionParameter: Text;
        NameSpace: Text;
        NameSpaceValue: Text;
        ReturnText: Text[500];
        TextBuilder: TextBuilder;
        Success: Boolean;
    // Node1Txt: label '<b:int>';
    // Node2Txt: label '</b:int>';
    // Id: text;
    begin
        EntradaMercanciaEnvelope(TextBuilder, PurchRcptHeader);

        SoapAction := 'soapAction';
        ActionName := 'setGR';
        NameSpace := 'good';
        NameSpaceValue := 'goodsReceiptService';

        Url := 'https://pre.invoway.com/services/GoodsReceiptService?wsdl';
        ActionParameter := 'request';

        Success := RequestWS(TextBuilder, ActionName, ActionParameter, Url, NameSpace, NameSpaceValue, ReturnText);

        if Success then begin
            PurchRcptHeader."Ditech_Invoway Timbrado" := true;
            PurchRcptHeader."Ditech_Invoway Error" := '';
        end
        else
            PurchRcptHeader."Ditech_Invoway Error" := ReturnText;

        PurchRcptHeader.Modify();

        // Id := COPYSTR(Autext, strpos(Autext, Node1Txt) + STRLEN(Node1Txt), strpos(Autext, Node2Txt) - (strpos(Autext, Node1Txt) + STRLEN(Node1Txt)));

    end;

    local procedure EntradaMercanciaEnvelope(var TextBuilder: TextBuilder; PurchRcptHeader: record "Purch. Rcpt. Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        GeneralLEdgerSetup: Record "General Ledger Setup";
        PurchLRcptineTextBuilder: TextBuilder;
        totalEntrada: Decimal;
        AmountLinea: Decimal;
    begin
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.SetFilter(Quantity, '<>0');
        if PurchRcptLine.FindSet() then
            repeat
                PurchLRcptineTextBuilder.Append('<linea>');
                PurchLRcptineTextBuilder.Append('<numeroLinea>' + Format(PurchRcptLine."Line No.") + '</numeroLinea>');
                PurchLRcptineTextBuilder.Append('<referenciaItem>' + PurchRcptLine."No." + '</referenciaItem>');
                PurchLRcptineTextBuilder.Append('<descripcion>' + PurchRcptLine.Description + '</descripcion>');
                PurchLRcptineTextBuilder.Append('<unidadesLinea>' + Format(PurchRcptLine.Quantity) + '</unidadesLinea>');
                PurchLRcptineTextBuilder.Append('<precioUnidad>' + Format(PurchRcptLine."Unit Price (LCY)") + '</precioUnidad>');
                AmountLinea := PurchRcptLine.Quantity * PurchRcptLine."Unit Price (LCY)";
                PurchLRcptineTextBuilder.Append('<totalLinea>' + Format(AmountLinea) + '</totalLinea>');
                PurchLRcptineTextBuilder.Append('</linea>');
                totalEntrada += AmountLinea;
            until PurchRcptLine.Next() = 0;

        CompanyInformation.Get();
        TextBuilder.Append('<idFiscalCliente>' + CompanyInformation."VAT Registration No." + '</idFiscalCliente>');

        TextBuilder.Append('<entrada>');

        TextBuilder.Append('<idEntrada>' + PurchRcptHeader."No." + '</idEntrada>');
        TextBuilder.Append('<fecha>' + Format(PurchRcptHeader."Posting Date", 0, 9) + '</fecha>');
        GeneralLEdgerSetup.Get();
        if PurchRcptHeader."Currency Code" <> '' then
            TextBuilder.Append('<divisa>' + PurchRcptHeader."Currency Code" + '</divisa>')
        else
            TextBuilder.Append('<divisa>' + GeneralLEdgerSetup."LCY Code" + '</divisa>');
        TextBuilder.Append('<documentoProveedor>' + PurchRcptHeader."Vendor Order No." + '</documentoProveedor>');
        TextBuilder.Append('<documentoTrasporte>' + PurchRcptHeader."Vendor Shipment No." + '</documentoTrasporte>');
        TextBuilder.Append('<totalEntrada>' + Format(totalEntrada) + '</totalEntrada>');
        TextBuilder.Append('<idPedido>' + PurchRcptHeader."Order No." + '</idPedido>');
        TextBuilder.Append('<indImpuestos>' + 'N' + '</indImpuestos>');

        Vendor.get(PurchRcptHeader."Buy-from Vendor No.");
        TextBuilder.Append('<proveedor>');
        TextBuilder.Append('<idProveedor>' + Vendor."VAT Registration No." + '</idProveedor>');
        TextBuilder.Append('<codigoProveedorERP>' + PurchRcptHeader."Buy-from Vendor No." + '</codigoProveedorERP>');
        TextBuilder.Append('<nombreProveedor>' + Vendor.Name + '</nombreProveedor>');
        TextBuilder.Append('<emailProveedor>' + Vendor."E-Mail" + '</emailProveedor>');
        TextBuilder.Append('<telefonoProveedor>' + Vendor."Phone No." + '</telefonoProveedor>');
        TextBuilder.Append('<direccionProveedor>' + Vendor.Address + ' ' + Vendor."Address 2" + '</direccionProveedor>');
        TextBuilder.Append('<ciudadProveedor>' + Vendor.City + '</ciudadProveedor>');
        TextBuilder.Append('<codigoPostalProveedor>' + Vendor."Post Code" + '</codigoPostalProveedor>');
        TextBuilder.Append('<paisProveedor>' + Vendor."Country/Region Code" + '</paisProveedor>');
        TextBuilder.Append('</proveedor>');

        TextBuilder.Append('<lineas>');
        TextBuilder.Append(PurchLRcptineTextBuilder.ToText());
        TextBuilder.Append('</lineas>');

        TextBuilder.Append('</entrada>');
    end;

    local procedure Export_XMLsend_toFile(TxtJSON: Text; NombreArchivo: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        //variables para el manejo del archivo
        DialogTitleLabelMsg: Label 'Exportar a archivo xml';
        FileName: Text;

    begin
        FileName := NombreArchivo + '.xml';
        TempBlob.CreateOutStream(OutStream);
        OutStream.Write(TxtJSON);
        TempBlob.CreateInStream(InStream);
        //guarda el archivo mostrando el cuadro de dialogo pasando la informacion que esta en instr
        file.DownloadFromStream(InStream, DialogTitleLabelMsg, '', '', FileName);
    end;

    local procedure RequestWS(TextBuilder: TextBuilder; ActionName: Text; ActionParameter: Text; Url: Text; NameSpace: Text; NameSpaceValue: Text; var ReturnText: Text[500]) Success: Boolean
    var
        HttpContent: HttpContent;
        HttpHeader: HttpHeaders;
        TxtContent: TextBuilder;
        TxtJSON: Text;
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        Text: Text;
    begin
        TxtContent.Append('<?xml version="1.0"?>');
        TxtContent.Append('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:' + NameSpace + '="' + NameSpaceValue + '">');
        TxtContent.Append('<soapenv:Header/>');
        TxtContent.Append('<soapenv:Body>');
        TxtContent.Append('<' + NameSpace + ':' + ActionName + '>');
        TxtContent.Append('<' + NameSpace + ':' + ActionParameter + '>');
        TxtContent.Append(TextBuilder.ToText());
        TxtContent.Append('</' + NameSpace + ':' + ActionParameter + '>');
        TxtContent.Append('</' + NameSpace + ':' + ActionName + '>');
        TxtContent.Append('</soapenv:Body>');
        TxtContent.Append('</soapenv:Envelope>');


        TxtJSON := TxtContent.ToText();
        Url := Url;
        HttpContent.WriteFrom(TxtJSON);
        HttpContent.GetHeaders(HttpHeader);
        HttpHeader.Remove('Content-Type');
        // HttpHeader.Remove('SOAPAction');
        HttpHeader.add('Content-Type', 'text/xml;charset=utf-8');
        // HttpHeader.add('SOAPAction', SoapAction);
        // HttpClient.DefaultRequestHeaders.add('cache-control', 'no-cache');
        if HttpClient.Post(url, HttpContent, HttpResponseMessage) then begin
            if HttpResponseMessage.IsSuccessStatusCode then
                Success := true
            else
                Success := false;
            //     Error('Devuelve :\\Status code: %1\Description: %2', HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);
            HttpResponseMessage.Content.ReadAs(Text);
            ReturnText := CopyStr(Text, 1, 500);
            Message('Peticion:\\%1\\Respuesta:\\%2', TxtJSON, Text);
            // Export_XMLSend_toFile(TxtJSON, ActionName + 'Peticion');
            // Export_XMLSend_toFile(Autext, ActionName + 'Respuesta');
        end;
    end;
}