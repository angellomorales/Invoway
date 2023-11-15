codeunit 50100 "Ditech_MessageMgt"
{

    procedure EntradaMercancia(Customer: record Customer)
    var
        Url: Text;
        SoapAction: Text;
        ActionName: Text;
        ActionParameter: Text;
        NameSpace: Text;
        NameSpaceValue: Text;
        Autext: Text;
        StringBuilder: TextBuilder;
    // Node1Txt: label '<b:int>';
    // Node2Txt: label '</b:int>';
    // Id: text;
    begin
        EntradaMercanciaEnvelope(StringBuilder, Customer);

        SoapAction := 'soapAction';
        ActionName := 'setGR';
        NameSpace := 'good';
        NameSpaceValue := 'goodsReceiptService';

        Url := 'Url';
        ActionParameter := 'request';

        Autext := RequestWS(StringBuilder, ActionName, ActionParameter, Url, SoapAction, NameSpace, NameSpaceValue);


        // Id := COPYSTR(Autext, strpos(Autext, Node1Txt) + STRLEN(Node1Txt), strpos(Autext, Node2Txt) - (strpos(Autext, Node1Txt) + STRLEN(Node1Txt)));

    end;

    local procedure EntradaMercanciaEnvelope(var StringBuilder: TextBuilder; Customer: record Customer)
    var
        CountryRegion: record "Country/Region";
    begin
        if CountryRegion.get(Customer."Country/Region Code") then;
        StringBuilder.Append('<Customers>');
        StringBuilder.Append('<CustomerDetail>');
        StringBuilder.Append('<Name>' + customer.Name + Customer."Name 2" + '</Name>');
        if Customer.Blocked = Customer.Blocked::" " then
            StringBuilder.Append('<CustomerType>Activo</CustomerType>')
        else
            StringBuilder.Append('<CustomerType>Inactivo</CustomerType>');
        StringBuilder.Append('<ExternalReference>' + Customer."No." + '</ExternalReference>');
        StringBuilder.append('<PaymentTerms>' + Customer."Payment Method Code" + '_' + Customer."Payment Terms Code" + '</PaymentTerms>');
        StringBuilder.Append('<CIF>' + Customer."VAT Registration No." + '</CIF>');
        StringBuilder.Append('<Addresses>');
        StringBuilder.Append('<Address>');
        StringBuilder.Append('<Name>' + Customer.Name + Customer."Name 2" + '</Name>');
        StringBuilder.Append('<Line1>' + Customer.Address + ' ' + Customer."Address 2" + '</Line1>');
        StringBuilder.Append('<Line2>' + Customer.City + '</Line2>');
        StringBuilder.Append('<Line3>' + customer.County + '</Line3>');
        StringBuilder.Append('<Country>' + CountryRegion.Name + '</Country>');
        StringBuilder.Append('<PostCode>' + customer."Post Code" + '</PostCode>');
        if Customer."Phone No." = '' then
            StringBuilder.Append('<Contacts/>')
        else begin
            StringBuilder.Append('<Contacts>');
            StringBuilder.Append('<Contact>');
            StringBuilder.Append('<CompanyNumber>' + Customer."Phone No." + '</CompanyNumber>');
            StringBuilder.Append('</Contact>');
            StringBuilder.Append('</Contacts>');
        end;
        StringBuilder.Append('</Address>');
        StringBuilder.Append('</Addresses>');
        StringBuilder.Append('</CustomerDetail>');
        StringBuilder.Append('</Customers>');
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

    local procedure RequestWS(StringBuilder: TextBuilder; ActionName: Text; ActionParameter: Text; Url: Text; SoapAction: Text; NameSpace: Text; NameSpaceValue: Text): Text
    var
        HttpContent: HttpContent;
        HttpHeader: HttpHeaders;
        TxtContent: TextBuilder;
        TxtJSON: Text;
        Autext: Text;
        HttpClient: HttpClient;
    // HttpResponseMessage: HttpResponseMessage;
    begin
        TxtContent.Append('<?xml version="1.0"?>');
        TxtContent.Append('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:' + NameSpace + '="' + NameSpaceValue + '">');
        TxtContent.Append('<soapenv:Header/>');
        TxtContent.Append('<soapenv:Body>');
        TxtContent.Append('<' + NameSpace + ':' + ActionName + '>');
        TxtContent.Append('<' + NameSpace + ':' + ActionParameter + '>');
        TxtContent.Append(StringBuilder.ToText());
        TxtContent.Append('</' + NameSpace + ':' + ActionParameter + '>');
        TxtContent.Append('</' + NameSpace + ':' + ActionName + '>');
        TxtContent.Append('</soapenv:Body>');
        TxtContent.Append('</soapenv:Envelope>');


        TxtJSON := TxtContent.ToText();
        Url := Url;
        HttpContent.WriteFrom(TxtJSON);
        HttpContent.GetHeaders(HttpHeader);
        HttpHeader.Remove('Content-Type');
        HttpHeader.Remove('SOAPAction');
        HttpHeader.add('Content-Type', 'text/xml;charset=utf-8');
        HttpHeader.add('SOAPAction', SoapAction);
        HttpClient.DefaultRequestHeaders.add('cache-control', 'no-cache');
        // if HttpClient.Post(url, HttpContent, HttpResponseMessage) then begin
        //     if not HttpResponseMessage.IsSuccessStatusCode then
        //         Error('Devuelve :\\Status code: %1\Description: %2', HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);
        //     HttpResponseMessage.Content.ReadAs(Autext);
        Message('Peticion:\\%1\\Respuesta:\\%2', TxtJSON, Autext);
        Export_XMLSend_toFile(TxtJSON, ActionName + 'Peticion');
        // Export_XMLSend_toFile(Autext, ActionName + 'Respuesta');
        exit(Autext);
        // end;
    end;
}