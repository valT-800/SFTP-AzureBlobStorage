codeunit 51123 "File Mgt. Refactor Examples"
{
    trigger OnRun()
    begin

    end;

    local procedure ServerCreateTempSubDirectory() DirectoryPath: Text
    var
        FileMgt: Codeunit "File Management";
        // SPLN1.00 - Start
        // ServerTempFile: Text;
        BlobTempFile: Text;
        ABSFileManagement: Codeunit "ABS File Management";
        g_recTempImportacion: Record "Temp Importaciones fact";
    //SPLN1.00 - End
    begin
        // SPLN1.00 - Start
        // ServerTempFile := FileMgt.ServerTempFileName('tmp');
        // DirectoryPath := FileMgt.CombinePath(ServerTempFile, Format(CreateGuid));
        // FileMgt.ServerCreateDirectory(DirectoryPath);
        // FileMgt.DeleteServerFile(ServerTempFile);
        BlobTempFile := ABSFileManagement.TempBlobFileName('tmp');
        DirectoryPath := FileMgt.CombinePath(BlobTempFile, Format(CreateGuid));
        ABSFileManagement.DeleteBlobFile(BlobTempFile);
        //SPLN1.00 - End
    end;

    local procedure CreateCsv(FileName: Text; Lines: List of [Text])
    var
        //SPLN1.00 - Start
        //NewFile: File;
        LF: Text[1];
        i: Integer;
        ostWriter: OutStream;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        ABSFileManagement: Codeunit "ABS File Management";
    //SPLN1.00 - End
    begin
        LF := ' ';
        LF[1] := 10;
        //SPLN1.00 - Start
        // NewFile.TextMode(false);
        // NewFile.WriteMode(true);
        // NewFile.Create(FileName, TEXTENCODING::UTF8);
        // NewFile.CreateOutStream(ostWriter);
        // for i := 0 to Lines.Count() - 1 do begin
        //     ostWriter.WriteText(Lines.Item(i));
        //     ostWriter.WriteText(LF);
        // end;
        // NewFile.Close();
        TempBlob.CreateOutStream(ostWriter, TextEncoding::UTF8);
        for i := 0 to Lines.Count() - 1 do begin
            ostWriter.WriteText(Lines.Get(i));
            ostWriter.WriteText(LF);
        end;
        TempBlob.CreateInStream(InStream);
        ABSFileManagement.SaveBlobFromInStream(FileName, InStream);
        //SPLN1.00 - End
    end;

    procedure DeleteTempFolder(TempFolderToDelete: Text)
    var
        ABSFileManagement: Codeunit "ABS File Management";
    begin
        // SPLN1.00 - Start
        // if TempFolderToDelete <> '' then
        //     FileMgt.ServerRemoveDirectory(TempFolderToDelete, true);
        if TempFolderToDelete <> '' then begin
            ABSFileManagement.RemoveDirectory(TempFolderToDelete);
        end;
        // SPLN1.00 - End
    end;

    procedure "#ImportarClientes"()
    var
        recConfigVentas: Record "Sales & Receivables Setup";
        txtPath: Text[250];
        Fichero: File;
        AbrirFichero: Text[200];
        NuevoFichero: Text[200];
        //SPLN1.00 - Start
        //recFile: Record File;
        recFile: Record "ABS Connector List" temporary;
        ABSFileManagement: Codeunit "ABS File Management";
        TempBlob: Codeunit "Temp Blob";
        //SPLN1.00 - End
        dlgVentana: Dialog;
        txtPathCompleto: Text[250];
        "txtLínea": Text[1024];
    begin
        //Test de los campos de configuración...
        recConfigVentas.Get;

        //SPLN1.00 - Start
        // recConfigVentas.TESTFIELD("Ruta destino VELIS/Clientes");

        // //guardamos rutas y nombre fichero...
        // txtPath := recConfigVentas."Ruta destino VELIS/Clientes";
        //SPLN1.00 - End


        //SPLN1.00 - Start
        recFile.Reset;
        // recFile.SetRange(Path, txtPath);
        // recFile.SetRange("Is a file", true);
        ABSFileManagement.GetDirectoryBlobFilesList(recFile, txtPath);
        recFile.SetFilter("Content Type", '<>%1', 'Directory');
        //SPLN1.00 - End
        if recFile.FindFirst then begin
            repeat
                if GuiAllowed then
                    dlgVentana.Open('Importando ficheros...');
                // SPLN1.00 - Start
                // txtPathCompleto := txtPath + '\' + recFile.Name;
                // Fichero.WriteMode(false);
                // Fichero.TextMode(false);
                // Fichero.Open(txtPathCompleto);

                // while "#LeerLineaCliente"(Fichero) <> 0 do begin
                //     "#QuitarEspacios";
                //     "#ActualizarLineaCliente";
                //     "#LimpiarVariables";
                // end;
                // Fichero.Close;
                // Erase(txtPathCompleto);
                txtPathCompleto := txtPath + '/' + recFile.Name;
                ABSFileManagement.GetBlob(TempBlob, txtPathCompleto);
                while "#LeerLineaCliente"(TempBlob) <> 0 do begin
                    "#QuitarEspacios";
                    "#ActualizarLineaCliente";
                    "#LimpiarVariables";
                end;
                ABSFileManagement.DeleteBlobFile(txtPathCompleto);
            // SPLN1.00 - End

            until recFile.Next = 0;
        end;
    end;


    procedure "#GetFileFromFTP"(codServidor: Code[20]; txtUsuario: Text[30]; "txtContraseña": Text[30]; txtArchivoOrigen: Text[250]; txtArchivoDestino: Text[1024])
    var
        //SPLN1.00 - Start
        //autSystemShell: Automation;
        //SPLN1.00 - End
        blnWaitOnReturn: Boolean;
        filArchivo: File;
        intResult: Integer;
        intWindowType: Integer;
        txtArchComandosFTP: Text[1024];
        txtArchivoBAT: Text[1024];
        //SPLN1.00 - Start
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ABSFileMgt: Codeunit "ABS File Management";
        InStream: InStream;
    //SPLN1.00 - End
    begin
        // En txtArchivoDestino, los nombres de las carpetas han de ser del estilo de MS-DOS (11 carácteres sin espacios)

        if (codServidor = '') or (txtArchivoOrigen = '') or (txtArchivoDestino = '') then
            exit;

        //-xx
        //txtArchComandosFTP := "#GetTempFileName";
        txtArchComandosFTP := 'C:\IRIS\ejecutable5';
        //+xx
        //SPLN1.00 - Start
        // filArchivo.WriteMode(true);
        // filArchivo.TextMode(true);
        // filArchivo.Create(txtArchComandosFTP);
        // if txtUsuario <> '' then
        //     filArchivo.Write('user ' + txtUsuario + ' ' + txtContraseña);
        // filArchivo.Write('binary');
        // filArchivo.Write('get "' + txtArchivoOrigen + '" "' + txtArchivoDestino + '"');
        // filArchivo.Write('bye');
        // filArchivo.Close;
        TempBlob.CreateOutStream(OutStream);
        if txtUsuario <> '' then
            OutStream.WriteText('user ' + txtUsuario + ' ' + txtContraseña);
        OutStream.WriteText('binary');
        OutStream.WriteText('get "' + txtArchivoOrigen + '" "' + txtArchivoDestino + '"');
        OutStream.WriteText('bye');
        TempBlob.CreateInStream(InStream);
        ABSFileMgt.SaveBlobFromInStream(txtArchComandosFTP, InStream);
        Clear(TempBlob);
        Clear(OutStream);
        //SPLN1.00 - End

        //-xx
        //txtArchivoBAT := "#GetTempFileName" + '.BAT';
        txtArchivoBAT := 'C:\IRIS\ejecutable5' + '.BAT';
        //+xx
        //SPLN1.00 - Start
        /*filArchivo.WriteMode(true);
        filArchivo.TextMode(true);
        filArchivo.Create(txtArchivoBAT);
        filArchivo.Write('@echo off');
        filArchivo.Write('ftp -v -i -n -s:"' + txtArchComandosFTP + '" ' + codServidor);
        filArchivo.Close;*/
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('@echo off');
        OutStream.WriteText('ftp -v -i -n -s:"' + txtArchComandosFTP + '" ' + codServidor);
        TempBlob.CreateInStream(InStream);
        ABSFileMgt.SaveBlobFromInStream(txtArchivoBAT, InStream);
        Clear(TempBlob);
        Clear(OutStream);
        //SPLN1.00 - End

        blnWaitOnReturn := true;
        intWindowType := 0;

        //-xx
        //CLEAR(autSystemShell);
        //CREATE(autSystemShell,FALSE,TRUE);
        //intResult := autSystemShell.Run(txtArchivoBAT, intWindowType, blnWaitOnReturn);
        ExecuteCMD(txtArchivoBAT);
        //+xx
        //SPLN1.00 - Start
        //Erase(txtArchComandosFTP);
        //Erase(txtArchivoBAT);
        ABSFileMgt.DeleteBlobFile(txtArchComandosFTP);
        ABSFileMgt.DeleteBlobFile(txtArchivoBAT);
        //SPLN1.00 - End
    end;


    local procedure OpenOrCreateFile(TipoFactura: Code[2]; Delete: Boolean): Text[250]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FileToUse: File;
        RutaFichero: Text[250];
        i: Integer;
        Pos: Integer;
        "año": Text;
        mes: Text;
        dia: Text;
        hora: Text;
        "min": Text;
        sec: Text;
        ExistsFile: Boolean;
        DocNumber: Code[20];
        //SPLN1.00 - Start
        ABSFileMgt: Codeunit "ABS File Management";
    //SPLN1.00 - End
    begin
        //-001
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup.TestField("Ruta fichero SII");
        RutaFichero := GeneralLedgerSetup."Ruta fichero SII";
        i := 1;
        while i < StrLen(RutaFichero) do begin
            if RutaFichero[i] = '\' then
                Pos := i;
            i += 1;
        end;
        if Pos <> StrLen(RutaFichero) then
            RutaFichero += '\';
        DevolverAnoMesDia(WorkDate, año, mes, dia);
        FormatTime(hora, min, sec);
        RutaFichero += CompanyName + '_' + TipoFactura + '_' + dia + mes +
        //-EXP01
        //          COPYSTR(FORMAT(DATE2DMY(WORKDATE,3)),STRLEN(FORMAT(DATE2DMY(WORKDATE,3)))-1,2) + '_' + hora + min + sec  + '.txt';
                  CopyStr(Format(Date2DMY(WorkDate, 3)), StrLen(Format(Date2DMY(WorkDate, 3))) - 1, 2) +
                  '_' + hora + min + sec + '_' + DocNumber + '.txt';
        //+EXP01

        //SPLN1.00 - Start
        // if not FileToUse.Open(RutaFichero) then
        //     FileToUse.Create(RutaFichero)
        // else
        //     ExistsFile := true;
        // FileToUse.Close;
        // if Delete then
        //     if not ExistsFile then
        //         Erase(RutaFichero);
        // exit(RutaFichero);
        if not ABSFileMgt.BlobFileExists(RutaFichero) then
            ABSFileMgt.CreateBlobFile(RutaFichero)
        else
            ExistsFile := true;
        if Delete then
            if not ExistsFile then
                ABSFileMgt.DeleteBlobFile(RutaFichero);
        exit(RutaFichero);
        //+001
    end;

}