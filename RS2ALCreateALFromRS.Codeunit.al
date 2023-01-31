codeunit 50140 "RS2AL_Create AL From RS"
{
    procedure CreateALFile(PackageCode: Code[20])
    begin
        InitTempBlob();
        CreateAL(PackageCode);
        ExportTxtFile(PackageCode + '.Codeunit.AL');
    end;

    procedure InitTempBlob()
    begin
        TmpBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        TmpBlob.CreateInStream(InStr, TextEncoding::UTF8);
    end;

    procedure WriteStringToTxtFile(StringToWrite: Text)
    begin
        OutStr.WriteText(StringToWrite);
    end;

    procedure WriteEmptyLineToTxtFile()
    var
        CR: Char;
        LF: Char;
    begin
        CR := 13;
        LF := 10;
        OutStr.WriteText(Format(CR, 0, '<CHAR>') + Format(LF, 0, '<CHAR>'));
    end;

    procedure ExportTxtFile(FileName: text)
    begin
        DownloadFromStream(InStr, '', '', '', FileName);
    end;

    procedure CreateAL(PackageCode: Code[20])
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageData: Record "Config. Package Data";
        i: Integer;
        UseProceduretxt: Text;
        TableNameTxt: text;
        FormatValue: Text;
    begin

        // Create AL File Header
        WriteStringToTxtFile('codeunit 5**** "' + PackageCode + '"');
        WriteEmptyLineToTxtFile();
        WriteStringToTxtFile('{');
        WriteEmptyLineToTxtFile();

        // Create Procedure that inserts the datas
        WriteStringToTxtFile('Procedure Code()');
        WriteEmptyLineToTxtFile();
        WriteStringToTxtFile('begin');
        WriteEmptyLineToTxtFile();

        Clear(ConfigPackageTable);
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigPackageTable.SetFilter("No. of Package Records", '<>%1', 0);
        if ConfigPackageTable.FindSet() then
            repeat
                if DoTableExists(ConfigPackageTable."Table ID") then begin
                    ConfigPackageTable.CalcFields("No. of Package Records", "Table Name");
                    // table name 
                    WriteStringToTxtFile('//  ' + ConfigPackageTable."Table Name");
                    WriteEmptyLineToTxtFile();

                    for i := 1 to ConfigPackageTable."No. of Package Records" DO begin
                        TableNameTxt := DelAllBadChr(ConfigPackageTable."Table Name");
                        UseProceduretxt := 'Create' + TableNameTxt + '(';
                        Clear(ConfigPackageData);
                        ConfigPackageData.SetRange("Package Code", PackageCode);
                        ConfigPackageData.SetRange("Table ID", ConfigPackageTable."Table ID");
                        ConfigPackageData.SetRange("No.", i);
                        if ConfigPackageData.FindSet() then
                            repeat
                                if GetFormatValue(ConfigPackageData, FormatValue) then
                                    UseProceduretxt += FormatValue + ',';
                            until ConfigPackageData.Next() = 0;

                        UseProceduretxt := CopyStr(UseProceduretxt, 1, StrLen(UseProceduretxt) - 1) + ');';
                        WriteStringToTxtFile(UseProceduretxt);
                        WriteEmptyLineToTxtFile();
                    end;
                end;
            until ConfigPackageTable.Next() = 0;
        WriteEmptyLineToTxtFile();
        WriteStringToTxtFile('end; ');

        Clear(ConfigPackageTable);
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigPackageTable.SetFilter("No. of Package Records", '<>%1', 0);
        if ConfigPackageTable.FindSet() then
            repeat
                if DoTableExists(ConfigPackageTable."Table ID") then begin
                    ConfigPackageTable.CalcFields("No. of Package Records", "Table Name");
                    TableNameTxt := DelAllBadChr(ConfigPackageTable."Table Name");
                    WriteEmptyLineToTxtFile();
                    // Entête procédure
                    WriteStringToTxtFile(GetProcedureHeader(ConfigPackageTable, TableNameTxt));
                    WriteEmptyLineToTxtFile();
                    //Variable procedure 
                    WriteStringToTxtFile('VAR');
                    WriteEmptyLineToTxtFile();
                    WriteStringToTxtFile(TableNameTxt + ': Record ' + '"' + ConfigPackageTable."Table Name" + '" ;');
                    WriteEmptyLineToTxtFile();
                    //corps  procedure 
                    WriteStringToTxtFile('begin');
                    WriteEmptyLineToTxtFile();
                    GetBodyHeader(ConfigPackageTable, TableNameTxt);
                    WriteStringToTxtFile('end;');
                    WriteEmptyLineToTxtFile();
                end;
            until ConfigPackageTable.Next() = 0;

        // Create AL File Footer
        WriteStringToTxtFile('}');

    end;

    procedure GetFormatValue(ConfigPackageData: Record "Config. Package Data"; var FormatVaue: Text): Boolean
    var
        Recfield: Record "field";
    begin
        if Recfield.Get(ConfigPackageData."Table ID", ConfigPackageData."Field ID") then
            case Recfield.Type of
                Recfield.Type::Integer:
                    if ConfigPackageData.Value <> '' then begin
                        FormatVaue := ConfigPackageData.Value;
                        exit(true);
                    end else begin
                        FormatVaue := Format(0);
                        exit(true);
                    end;
                Recfield.Type::Decimal:
                    if ConfigPackageData.Value <> '' then begin
                        FormatVaue := ConfigPackageData.Value;
                        exit(true);
                    end else begin
                        FormatVaue := Format(0);
                        exit(true);
                    end;
                Recfield.Type::Text:
                    begin
                        FormatVaue := '''' + ReplaceString(ConfigPackageData.Value, '''', '’') + '''';
                        exit(true);
                    end;

                Recfield.Type::Code:
                    begin
                        FormatVaue := '''' + ReplaceString(ConfigPackageData.Value, '''', '’') + '''';
                        exit(true);
                    end;
                Recfield.Type::Boolean:
                    case ConfigPackageData.Value of
                        'Oui':
                            begin
                                FormatVaue := 'true';
                                exit(true);
                            end;
                        'Non':
                            begin
                                FormatVaue := 'false';
                                exit(true);
                            end;
                        else begin
                            FormatVaue := ConfigPackageData.Value;
                            exit(true);
                        end;
                    end;
                Recfield.Type::date:
                    if ConfigPackageData.Value <> '' then begin
                        FormatVaue := GetDateValue(ConfigPackageData.Value);
                        exit(true);
                    end else begin
                        FormatVaue := '0D';
                        exit(true);
                    end;
                Recfield.Type::DateTime:
                    if ConfigPackageData.Value <> '' then begin
                        FormatVaue := ConfigPackageData.Value;
                        exit(true);
                    end else begin
                        FormatVaue := '0DT';
                        exit(true);
                    end;
                Recfield.Type::Option:
                    begin
                        FormatVaue := GetOptionValue(Recfield, ConfigPackageData."Table ID", ConfigPackageData.Value);
                        exit(true);
                    end;
                else
                    exit(false);
            end;
    end;

    procedure GetProcedureHeader(ConfigPackageTable: Record "Config. Package Table"; tableTxt: Text): Text
    var
        ConfigPackageField: Record "Config. Package Field";
        Recfield: Record "field";
        Proceduretxt: Text;
        FieldNameTxt: Text;
        FieldTypetxt: text;
    begin
        Proceduretxt := 'Procedure Create' + tableTxt + '(';
        clear(ConfigPackageField);
        ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
        ConfigPackageField.SetRange("Include Field", true);
        if ConfigPackageField.FindSet() then
            repeat
                if Recfield.Get(ConfigPackageTable."Table ID", ConfigPackageField."Field ID") then begin
                    FieldNameTxt := DelAllBadChr(Recfield.FieldName);
                    if GetFieldType(Recfield, FieldTypetxt) then begin
                        Proceduretxt += FieldNameTxt + ' : ';
                        Proceduretxt += FieldTypetxt + '; ';
                    end;
                end;
            until ConfigPackageField.Next() = 0;
        exit(CopyStr(Proceduretxt, 1, StrLen(Proceduretxt) - 2) + ')');
    end;


    procedure GetBodyHeader(ConfigPackageTable: Record "Config. Package Table"; tableTxt: Text)
    var
        ConfigPackageField: Record "Config. Package Field";
        Recfield: Record "field";
        FieldRecTxt: Text;
        FieldNameTxt: Text;
    begin
        WriteStringToTxtFile(tableTxt + '.Init();');
        WriteEmptyLineToTxtFile();
        Clear(ConfigPackageField);
        ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
        ConfigPackageField.SetRange("Include Field", true);
        if ConfigPackageField.FindSet() then
            repeat
                if Recfield.Get(ConfigPackageTable."Table ID", ConfigPackageField."Field ID") and GetFieldType(Recfield, FieldRecTxt) then begin
                    FieldNameTxt := DelAllBadChr(Recfield.FieldName);
                    if ConfigPackageField."Validate Field" then
                        WriteStringToTxtFile(tableTxt + '.Validate(' + '"' + Recfield.FieldName + '" ,' + FieldNameTxt + ' );')
                    else
                        WriteStringToTxtFile(tableTxt + '."' + Recfield.FieldName + '" := ' + FieldNameTxt + ' ;');
                    WriteEmptyLineToTxtFile();
                end;
            until ConfigPackageField.Next() = 0;
        WriteStringToTxtFile(tableTxt + '.Insert(true);');
        WriteEmptyLineToTxtFile();
    end;


    procedure GetFieldType(Recfield: Record "field"; var FieldTypetxt: text): Boolean
    begin
        case Recfield.Type of
            Recfield.Type::Integer:
                begin
                    FieldTypetxt := 'Integer';
                    exit(true);
                end;
            Recfield.Type::Decimal:
                begin
                    FieldTypetxt := 'Decimal';
                    exit(true);
                end;
            Recfield.Type::Text:
                begin
                    FieldTypetxt := 'Text[' + format(Recfield.Len) + ']';
                    exit(true);
                end;
            Recfield.Type::Code:
                begin
                    FieldTypetxt := 'Code[' + format(Recfield.Len) + ']';
                    exit(true);
                end;
            Recfield.Type::Boolean:
                begin
                    FieldTypetxt := 'Boolean';
                    exit(true);
                end;
            Recfield.Type::date:
                begin
                    FieldTypetxt := 'date';
                    exit(true);
                end;
            Recfield.Type::DateTime:
                begin
                    FieldTypetxt := 'DateTime';
                    exit(true);
                end;
            Recfield.Type::Option:
                begin
                    FieldTypetxt := 'Option';
                    exit(true);
                end;
            else
                exit(false);
        end;
    end;

    procedure ReplaceString(String: Text;
            FindWhat:
                Text;
            ReplaceWith:
                Text) NewString: Text
    var
        FindPos: Integer;
    begin
        FindPos := STRPOS(String, FindWhat);
        WHILE FindPos > 0 DO BEGIN
            NewString += DELSTR(String, FindPos) + ReplaceWith;
            String := COPYSTR(String, FindPos + STRLEN(FindWhat));
            FindPos := STRPOS(String, FindWhat);
        END;
        NewString += String;
    end;

    procedure GetOptionValue(Recfield: Record "field"; TableId: Integer; valueTxt: Text): Text
    var
        OptionCaption: Text;
        Result: list of [Text];
        Separators: Text;
    begin
        OptionCaption := GetOptionCaption(TableId, Recfield."No.");
        Result := OptionCaption.Split(',');
        if Result.Contains(valueTxt) then begin
            Separators := Format(Result.IndexOf(valueTxt) - 1);
            exit(Format(Result.IndexOf(valueTxt) - 1));
        end;
    end;

    procedure GetOptionCaption(TableId: Integer; FieldId: Integer) OptionCaption: Text
    var
        OptionRecordRef: RecordRef;
        OptionFieldRef: FieldRef;
    begin
        OptionRecordRef.Open(TableId);
        OptionFieldRef := OptionRecordRef.Field(FieldId);
        OptionCaption := OptionFieldRef.OptionCaption;
        OptionRecordRef.Close();
    end;

    procedure GetDateValue(DateAsTxt: Text): Text
    var
        DateL: Date;
        formatDate: text;
    begin
        if Evaluate(DateL, DateAsTxt) then begin
            formatDate := Format(DateL, 0, '<Year><Month,2><Day,2><Closing>D');
            if StrLen(formatDate) = 9 then
                exit(formatDate)
            else
                exit('20' + formatDate);
        end;
    end;

    procedure DoTableExists(TableID: Integer): Boolean
    var
        AllObj: Record AllObj;
    begin
        AllObj.Reset();
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", TableID);
        exit(Not AllObj.IsEmpty());
    end;

    procedure DelAllBadChr(FromString: Text): Text
    begin
        FromString := DELCHR(FromString, '=', ' ');
        FromString := DELCHR(FromString, '=', '.');
        FromString := DELCHR(FromString, '=', '<');
        FromString := DELCHR(FromString, '=', '>');
        FromString := DELCHR(FromString, '=', '-');
        FromString := DELCHR(FromString, '=', '/');
        FromString := DELCHR(FromString, '=', '\');
        exit(FromString);
    end;

    var
        TmpBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
}
