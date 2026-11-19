codeunit 57226 "SI Prok PF Template Writer"
{
    // XLSX layout renderer. Uses the approved workbook's styles and column widths.
    // Only xl/worksheets/sheet1.xml is replaced; the template is an app resource.
    // The report has exactly four visible content columns: B, C, D, E.

    var
        Rows: TextBuilder;
        Merges: TextBuilder;
        RowNo: Integer;
        MergeCount: Integer;

    procedure Start()
    begin
        Clear(Rows);
        Clear(Merges);
        RowNo := 1; // The approved layout begins at row 2.
        MergeCount := 0;
    end;

    procedure AddMainTitle()
    begin
        AddMerged('ПЛАН / ФАКТ ВИРОБНИЦТВА БЕТОНУ', 16, '19.5');
    end;

    procedure AddOrderHeader(OrderNo: Text; Concrete: Text; NeededAt: Text; Recipe: Text; ProjectName: Text; DeliverySite: Text; HasOrderedM3: Boolean; PlannedM3: Decimal; ActualM3: Decimal)
    begin
        AddTextPair('Заявка', OrderNo, 'Бетон', Concrete);
        AddTextPair('Дата/час потреби', NeededAt, 'Рецептура', Recipe);
        AddOptionalNumberPair('Проєкт', ProjectName, 'Замовлена кількість всього, м³', HasOrderedM3, PlannedM3);
        AddNumberPair('Точка розвантаження', DeliverySite, 'Вироблена кількість всього, м³', ActualM3);
        BlankRow();
        AddMerged('ВІДВАНТАЖЕННЯ ПО ПАРТІЯХ', 17, '15.75');
    end;

    procedure AddPartyHeader(PartyNo: Integer; TruckPlate: Text; DriverName: Text; ProductionAt: Text; HasPlanM3: Boolean; PlanM3: Decimal; ActualM3: Decimal)
    begin
        AddMerged(StrSubstNo('Партія №%1 · Автоміксер', PartyNo), 18, '15.75');
        NextRow('');
        AddTextCell('B', 'Автоміксер', 2);
        AddTextCell('C', TruckPlate, 3);
        AddTextCell('D', 'План, м³', 2);
        if HasPlanM3 then
            AddNumberCell('E', PlanM3, 4)
        else
            AddEmptyCell('E', 4);
        EndRow();
        NextRow('');
        AddTextCell('B', 'Водій', 2);
        AddTextCell('C', DriverName, 3);
        AddTextCell('D', 'Факт, м³', 2);
        AddNumberCell('E', ActualM3, 4);
        EndRow();
        NextRow('');
        AddTextCell('B', 'Дата/час виробництва', 2);
        AddTextCell('C', ProductionAt, 11);
        AddTextCell('D', 'Відхилення, м³', 2);
        if HasPlanM3 then
            AddNumberCell('E', ActualM3 - PlanM3, 12)
        else
            AddEmptyCell('E', 12);
        EndRow();
        AddMerged('МАТЕРІАЛИ ПАРТІЇ', 19, '');
        AddMaterialHeader();
    end;

    procedure AddMaterialSummaryHeader(WithoutOrder: Boolean)
    begin
        if WithoutOrder then
            AddMerged('ПІДСУМОК ВИТРАТ МАТЕРІАЛІВ', 17, '19.5')
        else
            AddMerged('ПІДСУМОК ВИТРАТ МАТЕРІАЛІВ ЗА ЗАЯВКОЮ', 17, '19.5');
        AddMaterialHeader();
    end;

    procedure AddMaterialHeader()
    begin
        NextRow('');
        AddTextCell('B', 'Матеріал', 5);
        AddTextCell('C', 'План, кг', 5);
        AddTextCell('D', 'Факт, кг', 5);
        AddTextCell('E', 'Відхилення, кг', 5);
        EndRow();
    end;

    procedure AddMaterial(MaterialName: Text; PlanKg: Decimal; ActualKg: Decimal; HighlightAsReplacement: Boolean)
    var
        NameStyle: Integer;
        NumberStyle: Integer;
        DifferenceStyle: Integer;
    begin
        NameStyle := 3;
        NumberStyle := 6;
        DifferenceStyle := 7;
        if HighlightAsReplacement then begin
            NameStyle := 8;
            NumberStyle := 9;
            DifferenceStyle := 10;
        end;
        NextRow('');
        AddTextCell('B', MaterialName, NameStyle);
        AddNumberCell('C', PlanKg, NumberStyle);
        AddNumberCell('D', ActualKg, NumberStyle);
        AddNumberCell('E', ActualKg - PlanKg, DifferenceStyle);
        EndRow();
    end;

    procedure AddReplacementNote(TitleText: Text; DetailText: Text)
    begin
        // Only call when the substitution link is explicitly established.
        AddMerged(TitleText, 20, '');
        if DetailText <> '' then
            AddMerged(DetailText, 13, '');
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
        // Template is the approved XLSX, not a newly styled Excel Buffer workbook.
        NavApp.GetResource('PlanFactTemplate.xlsx', TemplateStream);
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

    local procedure BuildSheetXml(): Text
    var
        Xml: TextBuilder;
    begin
        Xml.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
        Xml.Append('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
        Xml.Append(StrSubstNo('<dimension ref="B2:E%1"/>', RowNo));
        Xml.Append('<sheetViews><sheetView workbookViewId="0"><pane ySplit="8" topLeftCell="A9" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>');
        Xml.Append('<sheetFormatPr defaultColWidth="68.85546875" defaultRowHeight="15"/>');
        // Exact approved column widths, including the left margin A.
        Xml.Append('<cols>');
        Xml.Append('<col min="1" max="1" width="5.7109375" style="1" customWidth="1"/>');
        Xml.Append('<col min="2" max="2" width="30.28515625" style="1" customWidth="1"/>');
        Xml.Append('<col min="3" max="3" width="25.140625" style="1" customWidth="1"/>');
        Xml.Append('<col min="4" max="4" width="29.85546875" style="1" customWidth="1"/>');
        Xml.Append('<col min="5" max="5" width="14.5703125" style="1" customWidth="1"/>');
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

    local procedure AddTextPair(LeftCaption: Text; LeftValue: Text; RightCaption: Text; RightValue: Text)
    begin
        NextRow('');
        AddTextCell('B', LeftCaption, 2);
        AddTextCell('C', LeftValue, 3);
        AddTextCell('D', RightCaption, 2);
        AddTextCell('E', RightValue, 3);
        EndRow();
    end;

    local procedure AddOptionalNumberPair(LeftCaption: Text; LeftValue: Text; RightCaption: Text; HasRightValue: Boolean; RightValue: Decimal)
    begin
        NextRow('');
        AddTextCell('B', LeftCaption, 2);
        AddTextCell('C', LeftValue, 3);
        AddTextCell('D', RightCaption, 2);
        if HasRightValue then
            AddNumberCell('E', RightValue, 4)
        else
            AddEmptyCell('E', 4);
        EndRow();
    end;

    local procedure AddNumberPair(LeftCaption: Text; LeftValue: Text; RightCaption: Text; RightValue: Decimal)
    begin
        NextRow('');
        AddTextCell('B', LeftCaption, 2);
        AddTextCell('C', LeftValue, 3);
        AddTextCell('D', RightCaption, 2);
        AddNumberCell('E', RightValue, 4);
        EndRow();
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
