unit uModbusSrvClient;

interface

uses
  uThreadModbus, System.Net.Socket, System.SyncObjs,
  uMbBuf, uAddToLog ,uLog;

type
  TClientInfo = record
    ID: UInt64;
    BytesIn: UInt64;
    BytesOut: UInt64;
    localIP: string;
    remoteIP: string;
  end;

  TModbusSrvClient = class(TThreadModbus)
  private
  class var
    _globID: UInt64;
  var
    _ID: UInt64;
    _sID: string;
    _addr: UInt8;
    _answerSleep: UInt32;
    _answerType: Byte;
    _answerData: AnsiString;
    _clientSckt: TSocket;
    _byteIn, _byteOut: UInt64;
    _sleep: TEvent;//TLightweightEvent;
    _localIP, _remoteIP: string;
  protected
    procedure Execute; override;
    procedure TerminatedSet; override;
  public
    constructor Create(AClientSocket: TSocket; AThreadAddLog: TThreadAddToLog; AllowedMes: TLogTypes;
                       Addr: UInt8; AnwerSleep: UInt32; AnwerType: Byte; AnwerData: AnsiString);
    destructor Destroy; override;
    procedure setAnswerTypeAndData(AnswerType: Byte; AnswerData: AnsiString);
    procedure setAnswerSleepTime(AnswerSleep: UInt32);
    procedure getInfo(var ClientInfo: TClientInfo);
  end;

implementation

uses System.SysUtils, uMbDecode, uTools, uMbRegs,
  {Warnings}System.Types, {Warnings}System.Classes;

{ TModbusSrvClient }

constructor TModbusSrvClient.Create;
begin
  inherited Create(AThreadAddLog, AllowedMes, True);
  _sleep := TEvent.Create(nil, true, false, '');//TLightweightEvent.Create;
  _addr := Addr;
  _answerSleep := AnwerSleep;
  _answerType := AnwerType;
  _answerData := AnwerData;
  _ID := _globID;
  _sID := Format('Соединение #%d: ',[_ID]);
  Inc(_globID);
  _clientSckt := AClientSocket;
  FreeOnTerminate := True;
  _localIP  := format('%s:%d (%s)', [_clientSckt.LocalAddress,  _clientSckt.LocalPort, Tools.iff<string>(_clientSckt.LocalHost='', '-', _clientSckt.LocalHost)]);
  _remoteIP := format('%s:%d (%s)', [_clientSckt.RemoteAddress, _clientSckt.RemotePort, Tools.iff<string>(_clientSckt.RemoteHost='', '-', _clientSckt.RemoteHost)]);
end;

destructor TModbusSrvClient.Destroy;
begin
  FreeAndNil(_sleep);
  inherited;
end;

procedure TModbusSrvClient.setAnswerTypeAndData(AnswerType: Byte; AnswerData: AnsiString);
begin
  Synchronize(Self, procedure begin
    _answerType := AnswerType;
    _answerData := AnswerData;
  end);
end;

procedure TModbusSrvClient.setAnswerSleepTime(AnswerSleep: UInt32);
begin
  Synchronize(Self, procedure begin
    _answerSleep := AnswerSleep;
  end);
end;

procedure TModbusSrvClient.TerminatedSet;
begin
  inherited;
  _sleep.SetEvent;
end;

procedure TModbusSrvClient.Execute;
var
  buf: TBytes;
  bufI, bufO: TMBBuf;
  lng: UInt16;
begin
  try
    AddLog(ltInfo, _sID, 'Создано');
    //-------------------------------------
    while not Terminated do begin
      // ---------------------------
      //cnctSckt.Receive(buf); // не СИНХРОННЫЙ (не блокирует) почему-то
      buf := _clientSckt.EndReceiveBytes(_clientSckt.BeginReceive());
      if Length(buf)=0 then Break;
      bufI := TMBBytes(buf);
      // ---------------------------
      AddLog(ltRx, _sID, BytesToHex(bufI));
      inc(_byteIn, bufI.Count);
      // ---------------------------
      case _answerType of
        1: begin//Mute
          Continue;
        end;
        else begin//0,2,3,4 - запрос должен прийти нормальный
          //0,1 - ID транзакции — два байта
          //2,3 - ID протокола — два байта, нули
          //4,5 - длина пакета — два байта, старший затем младший, длина следующей за этим полем части пакета
          //6,7 - адрес, фунция
          lng := bufI.ItemW[4];
          if lng+6<bufI.Count then Continue;
          if (_addr=0) or (bufI.Item[6]=_addr) then begin
            if ModbusServerParse(bufI.copy(7,lng-1), MBReg, bufO) then begin
              case _answerType of
                2:begin//Error
                  lng := 3;
                  bufO := bufI[0] + bufI[1] + bufI[2] + bufI[3] + TMBBuf(lng) +
                          bufI[6] + TMBBuf(bufI.Item[7] or $80) + _answerData[1];
                end;
                3:begin//Data
                  lng := 2 + Length(_answerData);
                  bufO := bufI[0] + bufI[1] + bufI[2] + bufI[3] + TMBBuf(lng) +
                          bufI[6] + bufI[7] + _answerData;
                end;
                4:begin//ADU
                  lng := Length(_answerData);
                  bufO := bufI[0] + bufI[1] + bufI[2] + bufI[3] + TMBBuf(lng) +
                          _answerData;
                end;
                5:begin//Full
                  bufO := _answerData;
                end;
                else begin //Nornal
                  lng := bufO.Count + 1;
                  bufO := bufI[0] + bufI[1] + bufI[2] + bufI[3] + TMBBuf(lng) +
                          bufI[6] + bufO;
                end;
              end;
            end else begin //as Nornal
                  lng := bufO.Count + 1;
                  bufO := bufI[0] + bufI[1] + bufI[2] + bufI[3] + TMBBuf(lng) +
                          bufI[6] + bufO;
            end;
            //-----------------------
            if _answerSleep>0 then begin
              _sleep.ResetEvent;
              _sleep.WaitFor(_answerSleep);
              if Terminated then Continue;
            end;
            //-----------------------
            AddLog(ltTx, _sID, BytesToHex(bufO));
            _clientSckt.Send(TBytes(TMBBytes(bufO)));
            inc(_byteOut, bufO.Count);
            //-----------------------
          end;
        end;
      end;
    end;
  except
//    on e: ESocketError do begin
//      AddLog(ltError, _sID+e.Message);
//    end;
    on e: Exception do begin
      AddLog(ltError, _sID, e.Message);
    end;
  end;
  //-------------------------------------
  try
    _clientSckt.Close(true);
  finally
    AddLog(ltInfo, _sID, 'Закрыто');
  end;
end;

procedure TModbusSrvClient.getInfo(var ClientInfo: TClientInfo);
var clientInf: TClientInfo;
begin
  Synchronize( Self, procedure begin
    with clientInf do begin
      ID := _ID;
      BytesIn := _byteIn;
      BytesOut := _byteOut;
      localIP := _localIP;
      remoteIP := _remoteIP;
    end;
  end);
  ClientInfo := clientInf;
end;

initialization
  TModbusSrvClient._globID := 0;
end.
