codeunit 57229 "SI Prok PF Sum Writer"
{
    // R4: period summary XLSX renderer. Styles/widths are taken from the approved
    // Resources/PlanFactSumTemplate.xlsx, with only sheet1.xml replaced.
    // B:E are the only content columns; the template's placeholder notes are omitted.

    var
        Rows: TextBuilder;
        Merges: TextBuilder;
        RowNo: Integer;
        MergeCount: Integer;

    procedure Start(FromDate: Date; ToDate: Date)
    begin
        Clear(Rows);
        Clear(Merges);
        RowNo := 1;
        MergeCount := 0;
        AddMerged('ПІДСУМКОВИЙ ПЛАН / ФАКТ ВИРОБНИЦТВА БЕТОНУ', 10, '19.5');
        NextRow('18.75');
        AddTextCell('B', 'Початкова дата', 13);
        AddDateCell('C', FromDate, 25);
        AddTextCell('D', 'Кінцева дата', 13);
        AddDateCell('E', ToDate, 25);
        EndRow();
        BlankRow();
    end;

    procedure AddConcrete(ConcreteName: Text; RecipeName: Text; HasPlan: Boolean; PlanM3: Decimal; HasActual: Boolean; ActualM3: Decimal)
    begin
        NextRow('17.25');
        AddTextCell('B', 'Бетон', 19);
        AddTextCell('C', ConcreteName, 16);
        AddTextCell('D', 'Рецептура', 19);
        AddTextCell('E', RecipeName, 16);
        EndRow();

        NextRow('17.25');
        AddTextCell('B', 'Замовлена кількість, м³', 20);
        if HasPlan then
            AddNumberCell('C', PlanM3, 21)
        else
            AddEmptyCell('C', 21);
        EndRow();

        NextRow('17.25');
        AddTextCell('B', 'Вироблена кількість, м³', 20);
        if HasActual then
            AddNumberCell('C', ActualM3, 21)
        else
            AddEmptyCell('C', 21);
        EndRow();

        NextRow('17.25');
        AddTextCell('B', 'Відхилення, м³', 20);
        if HasPlan and HasActual then
            AddNumberCell('C', ActualM3 - PlanM3, 22)
        else
            AddEmptyCell('C', 22);
        EndRow();
        AddMaterialsTitle('ПІДСУМКОВІ ВИТРАТИ МАТЕРІАЛІВ');
    end;

    procedure AddGrandMaterialsTitle()
    begin
        AddMaterialsTitle('ЗАГАЛЬНІ ВИТРАТИ МАТЕРІАЛІВ НА ВИРОБНИЦТВО ЗА ПЕРІОД');
    end;

    procedure AddMaterial(MaterialName: Text; PlanKg: Decimal; ActualKg: Decimal; Highlight: Boolean)
    var
        TextStyle: Integer;
        NumberStyle: Integer;
        DeltaStyle: Integer;
    begin
        TextStyle := 2;
        NumberStyle := 4;
        DeltaStyle := 5;
        if Highlight then begin
            TextStyle := 6;
            NumberStyle := 7;
            DeltaStyle := 8;
        end;
        NextRow('');
        AddTextCell('B', MaterialName, TextStyle);
        AddNumberCell('C', PlanKg, NumberStyle);
        AddNumberCell('D', ActualKg, NumberStyle);
        AddNumberCell('E', ActualKg - PlanKg, DeltaStyle);
        EndRow();
    end;

    procedure BlankRow()
    begin
        RowNo += 1;
    end;

    procedure Download(FileName: Text)
    var
        Archive: Codeunit "Data Compression";
        XmlBlob: Codeunit "Temp Blob";
        ResultBlob: Codeunit "Temp Blob";
        TemplateStream: InStream;
        XmlOut: OutStream;
        XmlIn: InStream;
        ResultIn: InStream;
        DownloadName: Text;
    begin
        NavApp.GetResource('PlanFactSumTemplate.xlsx', TemplateStream);
        Archive.OpenZipArchive(TemplateStream, true);
        Archive.RemoveEntry('xl/worksheets/sheet1.xml');
        XmlBlob.CreateOutStream(XmlOut, TextEncoding::UTF8);
        XmlOut.WriteText(BuildSheetXml());
        XmlBlob.CreateInStream(XmlIn);
        Archive.AddEntry(XmlIn, 'xl/worksheets/sheet1.xml');
        Archive.SaveZipArchive(ResultBlob);
        Archive.CloseZipArchive();
        ResultBlob.CreateInStream(ResultIn);
        DownloadName := FileName + '.xlsx';
        DownloadFromStream(ResultIn, '', '', 'Excel (*.xlsx)|*.xlsx', DownloadName);
    end;

    local procedure AddMaterialsTitle(Heading: Text)
    begin
        AddMerged(Heading, 14, '');
        NextRow('');
        AddTextCell('B', 'Матеріал', 3);
        AddTextCell('C', 'План, кг', 3);
        AddTextCell('D', 'Факт, кг', 3);
        AddTextCell('E', 'Відхилення, кг', 3);
        EndRow();
    end;

    local procedure BuildSheetXml(): Text
    var
        Xml: TextBuilder;
    begin
        Xml.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
        Xml.Append('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
        Xml.Append(StrSubstNo('<dimension ref="B2:E%1"/>', RowNo));
        // Only the title and date range are frozen; every concrete block scrolls.
        Xml.Append('<sheetViews><sheetView workbookViewId="0"><pane ySplit="3" topLeftCell="A4" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>');
        Xml.Append('<sheetFormatPr defaultColWidth="68.85546875" defaultRowHeight="15"/>');
        Xml.Append('<cols>');
        Xml.Append('<col min="1" max="1" width="5.7109375" style="1" customWidth="1"/>');
        Xml.Append('<col min="2" max="2" width="30.28515625" style="1" customWidth="1"/>');
        Xml.Append('<col min="3" max="3" width="25.140625" style="1" customWidth="1"/>');
        Xml.Append('<col min="4" max="4" width="38.28515625" style="1" customWidth="1"/>');
        Xml.Append('<col min="5" max="5" width="14.7109375" style="1" customWidth="1"/>');
        Xml.Append('</cols>');
        Xml.Append('<sheetData>');
        Xml.Append(Rows.ToText());
        Xml.Append('</sheetData>');
        Xml.Append(StrSubstNo('<mergeCells count="%1">', MergeCount));
        Xml.Append(Merges.ToText());
        Xml.Append('</mergeCells>');
        Xml.Append('<pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/>');
        Xml.Append('</worksheet>');
        exit(Xml.ToText());
    end;

    local procedure AddMerged(Value: Text; StyleId: Integer; Height: Text)
    begin
        NextRow(Height);
        AddTextCell('B', Value, StyleId);
        AddEmptyCell('C', StyleId);
        AddEmptyCell('D', StyleId);
        AddEmptyCell('E', StyleId);
        EndRow();
        Merges.Append(StrSubstNo('<mergeCell ref="B%1:E%1"/>', RowNo));
        MergeCount += 1;
    end;

    local procedure NextRow(Height: Text)
    begin
        RowNo += 1;
        if Height = '' then
            Rows.Append(StrSubstNo('<row r="%1">', RowNo))
        else
            Rows.Append(StrSubstNo('<row r="%1" ht="%2" customHeight="1">', RowNo, Height));
    end;

    local procedure EndRow()
    begin
        Rows.Append('</row>');
    end;

    local procedure AddTextCell(ColumnName: Text; Value: Text; StyleId: Integer)
    begin
        Rows.Append(StrSubstNo('<c r="%1%2" s="%3" t="inlineStr"><is><t xml:space="preserve">%4</t></is></c>',
            ColumnName, RowNo, StyleId, EscapeXml(Value)));
    end;

    local procedure AddNumberCell(ColumnName: Text; Value: Decimal; StyleId: Integer)
    begin
        Rows.Append(StrSubstNo('<c r="%1%2" s="%3"><v>%4</v></c>',
            ColumnName, RowNo, StyleId, Format(Value, 0, 9)));
    end;

    local procedure AddDateCell(ColumnName: Text; Value: Date; StyleId: Integer)
    var
        Serial: Integer;
    begin
        Serial := Value - DMY2Date(30, 12, 1899);
        Rows.Append(StrSubstNo('<c r="%1%2" s="%3"><v>%4</v></c>',
            ColumnName, RowNo, StyleId, Serial));
    end;

    local procedure AddEmptyCell(ColumnName: Text; StyleId: Integer)
    begin
        Rows.Append(StrSubstNo('<c r="%1%2" s="%3"/>', ColumnName, RowNo, StyleId));
    end;

    local procedure EscapeXml(Value: Text): Text
    var
        Result: TextBuilder;
        Character: Text[1];
        I: Integer;
    begin
        for I := 1 to StrLen(Value) do begin
            Character := CopyStr(Value, I, 1);
            case Character of
                '&': Result.Append('&amp;');
                '<': Result.Append('&lt;');
                '>': Result.Append('&gt;');
                '"': Result.Append('&quot;');
                else Result.Append(Character);
            end;
        end;
        exit(Result.ToText());
    end;
}
