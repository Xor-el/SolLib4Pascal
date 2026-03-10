{ * ************************************************************************ * }
{ *                              SolLib Library                              * }
{ *                       Author - Ugochukwu Mmaduekwe                       * }
{ *              Github Repository <https://github.com/Xor-el>               * }
{ *                                                                          * }
{ *  Distributed under the MIT software license, see the accompanying file   * }
{ *                                 LICENSE                                  * }
{ *         or visit http://www.opensource.org/licenses/mit-license.         * }
{ *                                                                          * }
{ *                            Acknowledgements:                             * }
{ *                                                                          * }
{ *  Thanks to InstallAware (https://www.installaware.com/) for sponsoring   * }
{ *                     the development of this library                      * }
{ * ************************************************************************ * }

(* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& *)

unit TokenSwapProgramTests;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpWallet,
  SlpAccount,
  SlpPublicKey,
  SlpTransactionInstruction,
  SlpMessageDomain,
  SlpInstructionDecoder,
  SlpTokenSwapModel,
  SlpTokenSwapProgram,
  SlpDecodedInstruction,
  SolLibProgramTestCase;

type
  TTokenSwapProgramTests = class(TSolLibProgramTestCase)
  private
   const
    MnemonicWords = 'route clerk disease box emerge airport loud waste attitude film army tray ' +
    'forward deal onion eight catalog surface unit card window walnut wealth medal';

    InitializeMessage =
      'AgAHC1MuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft3/FflD5yxhXv/GyRPQxWneSI1' +
      '9VP2k43gUpVYG2jNHwarv91zFFZ0BDXh2dnixS0rka8rnVm8/lwluHEzfmVwaq9yV5EkRlspI5d' +
      'TBei2pTw72+yOOEUXqFwgg1djn1hXAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
      'AAAAAD0E4aXqh2tQhGa5IVDemLCaLk5I4fWxHtDzbxweno50QGqkt1zAcrZOVxGCNL6Xm7' +
      'NI3/Bm+44+nxDHxEdV6rYjoSyYQV+btxvbXHxDsERTxTz2CLMUCdl3qxnNxEiIzEl6yl4BybR' +
      'MuKQsQucwG8zcPF4h2aVMSq1AidCfnxnLgbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+' +
      '/wCpBqU6rja/SG+12TgmTuZF10tgFuD0euuz7BZDi/e/++Hmyh7pP4homUV4nZbFzDiNooTfV0' +
      'TICDNPFy0DXREIwgIEAgABNAAAAADAADAAAAAAAEQBAAAAAAAABqU6rja/SG+12TgmT' +
      'uZF10tgFuD0euuz7BZDi/e/++EKCAEFBgcCCAMJYwD9GQAAAAAAAAAQJwAAAAAAAAUAA' +
      'AAAAAAAECcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFAAAAAAAAABkAAAAAAAAAAAAA' +
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==';

    SwapMessage =
      'AQAEC1MuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft37QqyFDtQcH7hIYXKOEvkCQa+' +
      'SmTK5A6OGMeeZooUoakBqpLdcwHK2TlcRgjS+l5uzSN/wZvuOPp8Qx8RHVeq2I6EsmEFfm7cb' +
      '21x8Q7BEU8U89gizFAnZd6sZzcRIiMxwQavoWObAlxFe84OJSfFUsLJIhR4Q2+v+4N9Vt58Vla' +
      'rv91zFFZ0BDXh2dnixS0rka8rnVm8/lwluHEzfmVwaiXrKXgHJtEy4pCxC5zAbzNw8XiHZpUxKr' +
      'UCJ0J+fGcu/FflD5yxhXv/GyRPQxWneSI19VP2k43gUpVYG2jNHwb0E4aXqh2tQhGa5IVDemL' +
      'CaLk5I4fWxHtDzbxweno50Qbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpBqU6rja/SG' +
      '+12TgmTuZF10tgFuD0euuz7BZDi/e/++H0144NBdw24rNWa3osyQqbSeyvVJGFXla9Rpj5nnnRRQ' +
      'EKCgcIAAECAwQFBgkRAQDKmjsAAAAAIKEHAAAAAAA=';

    DepositAllTokenTypesMessage =
      'AQAEC1MuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft37QqyFDtQcH7hIYXKOEvkCQa+S' +
      'mTK5A6OGMeeZooUoanBBq+hY5sCXEV7zg4lJ8VSwskiFHhDb6/7g31W3nxWVgGqkt1zAcrZOV' +
      'xGCNL6Xm7NI3/Bm+44+nxDHxEdV6rYjoSyYQV+btxvbXHxDsERTxTz2CLMUCdl3qxnNxEiIzGr' +
      'v91zFFZ0BDXh2dnixS0rka8rnVm8/lwluHEzfmVwaq9yV5EkRlspI5dTBei2pTw72+yOOEUXqFwg' +
      'g1djn1hX/FflD5yxhXv/GyRPQxWneSI19VP2k43gUpVYG2jNHwb0E4aXqh2tQhGa5IVDemLCaLk' +
      '5I4fWxHtDzbxweno50Qbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpBqU6rja/SG+12' +
      'TgmTuZF10tgFuD0euuz7BZDi/e/++G/iXGArXvtQXqAznGhXSmATofHCuoBlpHxgPk4SfhBjwEKCg' +
      'cIAAECAwQFBgkZAkBCDwAAAAAAAOh2SBcAAAAA6HZIFwAAAA==';

    WithdrawAllTokenTypesMessage =
      'AQAEDFMuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft3q7/dcxRWdAQ14dnZ4sUtK5GvK' +
      '51ZvP5cJbhxM35lcGqvcleRJEZbKSOXUwXotqU8O9vsjjhFF6hcIINXY59YVwGqkt1zAcrZOVxGC' +
      'NL6Xm7NI3/Bm+44+nxDHxEdV6rYjoSyYQV+btxvbXHxDsERTxTz2CLMUCdl3qxnNxEiIzHtCrI' +
      'UO1BwfuEhhco4S+QJBr5KZMrkDo4Yx55mihShqcEGr6FjmwJcRXvODiUnxVLCySIUeENvr/uD' +
      'fVbefFZWJespeAcm0TLikLELnMBvM3DxeIdmlTEqtQInQn58Zy78V+UPnLGFe/8bJE9DFad5Ij' +
      'X1U/aTjeBSlVgbaM0fBvQThpeqHa1CEZrkhUN6YsJouTkjh9bEe0PNvHB6ejnRBt324ddloZPZy+' +
      'FGzut5rBy0he1fWzeROoz1hX7/AKkGpTquNr9Ib7XZOCZO5kXXS2AW4PR667PsFkOL97/74RgZ' +
      'qeIKqmWN9s3Opx7A0mQO3EPmMmA+8ndUoI0JQ3gfAQsLCAkAAQIDBAUGBwoZA0BCDwAA' +
      'AAAA6AMAAAAAAADoAwAAAAAAAA==';

    DepositSingleTokenTypeExactAmountInMessage =
      'AQAEClMuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft37QqyFDtQcH7hIYXKOEvkCQa+' +
      'SmTK5A6OGMeeZooUoakBqpLdcwHK2TlcRgjS+l5uzSN/wZvuOPp8Qx8RHVeq2I6EsmEFfm7c' +
      'b21x8Q7BEU8U89gizFAnZd6sZzcRIiMxq7/dcxRWdAQ14dnZ4sUtK5GvK51ZvP5cJbhxM35lc' +
      'GqvcleRJEZbKSOXUwXotqU8O9vsjjhFF6hcIINXY59YV/xX5Q+csYV7/xskT0MVp3kiNfVT9p' +
      'ON4FKVWBtozR8G9BOGl6odrUIRmuSFQ3piwmi5OSOH1sR7Q828cHp6OdEG3fbh12Whk9nL4' +
      'UbO63msHLSF7V9bN5E6jPWFfv8AqQalOq42v0hvtdk4Jk7mRddLYBbg9Hrrs+wWQ4v3v/vhzr' +
      'NmDrCfcB0Cg6zcl3Vo7qSZvl3ypatPmPfURasFfUABCQkGBwABAgMEBQgRBADKmjsAAAAA6A' +
      'MAAAAAAAA=';

    WithdrawSingleTokenTypeExactAmountOutMessage =
      'AQAEC1MuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft3q7/dcxRWdAQ14dnZ4sUtK5Gv' +
      'K51ZvP5cJbhxM35lcGqvcleRJEZbKSOXUwXotqU8O9vsjjhFF6hcIINXY59YVwGqkt1zAcrZOV' +
      'xGCNL6Xm7NI3/Bm+44+nxDHxEdV6rYjoSyYQV+btxvbXHxDsERTxTz2CLMUCdl3qxnNxEiIz' +
      'HtCrIUO1BwfuEhhco4S+QJBr5KZMrkDo4Yx55mihShqSXrKXgHJtEy4pCxC5zAbzNw8XiHZp' +
      'UxKrUCJ0J+fGcu/FflD5yxhXv/GyRPQxWneSI19VP2k43gUpVYG2jNHwb0E4aXqh2tQhGa5I' +
      'VDemLCaLk5I4fWxHtDzbxweno50Qbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpBq' +
      'U6rja/SG+12TgmTuZF10tgFuD0euuz7BZDi/e/++G6sYz49vuFr7rLN/dMfUEvpaHxP6DxaNZa' +
      'SUp0zrIUswEKCgcIAAECAwQFBgkRBUBCDwAAAAAAoIYBAAAAAAA=';

    { Program Id & Expected Instruction Data }
    class function TokenSwapProgramIdBytes: TBytes; static;
    class function ExpectedInitializeData: TBytes; static;
    class function ExpectedSwapData: TBytes; static;
    class function ExpectedDepositAllTokenTypesData: TBytes; static;
    class function ExpectedWithdrawAllTokenTypesData: TBytes; static;
    class function ExpectedDepositSingleTokenTypeExactAmountInData: TBytes; static;
    class function ExpectedWithdrawSingleTokenTypeExactAmountOutData: TBytes; static;

   (* { Base64 (MessagePack) Encoded Transactions for Decode tests }
    class function InitializeMessage: string; static;
    class function SwapMessage: string; static;
    class function DepositAllTokenTypesMessage: string; static;
    class function WithdrawAllTokenTypesMessage: string; static;
    class function DepositSingleTokenTypeExactAmountInMessage: string; static;
    class function WithdrawSingleTokenTypeExactAmountOutMessage: string; static; *)
  published
    { Builder tests }
    procedure TestInitialize;
    procedure TestSwap;
    procedure TestDepositAllTokenTypes;
    procedure TestWithdrawAllTokenTypes;
    procedure TestDepositSingleTokenTypeExactAmountInTypes;
    procedure TestWithdrawSingleTokenTypeExactAmountOutTypes;

    { Decode (round-trip) tests - value-by-value }
    procedure InitializeDecodeTest;
    procedure SwapDecodeTest;
    procedure DepositAllTokenTypesDecodeTest;
    procedure WithdrawAllTokenTypesDecodeTest;
    procedure DepositSingleTokenTypeExactAmountInDecodeTest;
    procedure WithdrawSingleTokenTypeExactAmountOutDecodeTest;
  end;

implementation

class function TTokenSwapProgramTests.TokenSwapProgramIdBytes: TBytes;
begin
  Result := TBytes.Create(
    6,165,58,174,54,191,72,111,181,217,56,38,
    78,230,69,215,75,96,22,224,244,122,235,
    179,236,22,67,139,247,191,251,225
  );
end;

class function TTokenSwapProgramTests.ExpectedInitializeData: TBytes;
begin
  Result := TBytes.Create(
    0,254,1,0,0,0,0,0,0,0,100,0,0,0,0,0,0,0,1,0,0,0,0,0,
    0,0,100,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,
    0,1,0,0,0,0,0,0,0,232,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  );
end;

class function TTokenSwapProgramTests.ExpectedSwapData: TBytes;
begin
  Result := TBytes.Create(
    1,128,26,6,0,0,0,0,0,32,179,129,0,0,0,0,0
  );
end;

class function TTokenSwapProgramTests.ExpectedDepositAllTokenTypesData: TBytes;
begin
  Result := TBytes.Create(
    2,4,0,0,0,0,0,0,0,32,179,129,0,0,0,0,0,160,15,0,0,0,0,0,0
  );
end;

class function TTokenSwapProgramTests.ExpectedWithdrawAllTokenTypesData: TBytes;
begin
  Result := TBytes.Create(
    3,4,0,0,0,0,0,0,0,160,15,0,0,0,0,0,0,32,179,129,0,0,0,0,0
  );
end;

class function TTokenSwapProgramTests.ExpectedDepositSingleTokenTypeExactAmountInData: TBytes;
begin
  Result := TBytes.Create(
    4,160,15,0,0,0,0,0,0,4,0,0,0,0,0,0,0
  );
end;

class function TTokenSwapProgramTests.ExpectedWithdrawSingleTokenTypeExactAmountOutData: TBytes;
begin
  Result := TBytes.Create(
    5,160,15,0,0,0,0,0,0,4,0,0,0,0,0,0,0
  );
end;

(*
class function TTokenSwapProgramTests.InitializeMessage: string;
begin
  Result :=
    'AgAHC1MuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft3/FflD5yxhXv/GyRPQxWneSI1' +
    '9VP2k43gUpVYG2jNHwarv91zFFZ0BDXh2dnixS0rka8rnVm8/lwluHEzfmVwaq9yV5EkRlspI5d' +
    'TBei2pTw72+yOOEUXqFwgg1djn1hXAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
    'AAAAAD0E4aXqh2tQhGa5IVDemLCaLk5I4fWxHtDzbxweno50QGqkt1zAcrZOVxGCNL6Xm7' +
    'NI3/Bm+44+nxDHxEdV6rYjoSyYQV+btxvbXHxDsERTxTz2CLMUCdl3qxnNxEiIzEl6yl4BybR' +
    'MuKQsQucwG8zcPF4h2aVMSq1AidCfnxnLgbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+' +
    '/wCpBqU6rja/SG+12TgmTuZF10tgFuD0euuz7BZDi/e/++Hmyh7pP4homUV4nZbFzDiNooTfV0' +
    'TICDNPFy0DXREIwgIEAgABNAAAAADAADAAAAAAAEQBAAAAAAAABqU6rja/SG+12TgmT' +
    'uZF10tgFuD0euuz7BZDi/e/++EKCAEFBgcCCAMJYwD9GQAAAAAAAAAQJwAAAAAAAAUAA' +
    'AAAAAAAECcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFAAAAAAAAABkAAAAAAAAAAAAA' +
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==';
end;

class function TTokenSwapProgramTests.SwapMessage: string;
begin
  Result :=
    'AQAEC1MuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft37QqyFDtQcH7hIYXKOEvkCQa+' +
    'SmTK5A6OGMeeZooUoakBqpLdcwHK2TlcRgjS+l5uzSN/wZvuOPp8Qx8RHVeq2I6EsmEFfm7cb' +
    '21x8Q7BEU8U89gizFAnZd6sZzcRIiMxwQavoWObAlxFe84OJSfFUsLJIhR4Q2+v+4N9Vt58Vla' +
    'rv91zFFZ0BDXh2dnixS0rka8rnVm8/lwluHEzfmVwaiXrKXgHJtEy4pCxC5zAbzNw8XiHZpUxKr' +
    'UCJ0J+fGcu/FflD5yxhXv/GyRPQxWneSI19VP2k43gUpVYG2jNHwb0E4aXqh2tQhGa5IVDemL' +
    'CaLk5I4fWxHtDzbxweno50Qbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpBqU6rja/SG' +
    '+12TgmTuZF10tgFuD0euuz7BZDi/e/++H0144NBdw24rNWa3osyQqbSeyvVJGFXla9Rpj5nnnRRQ' +
    'EKCgcIAAECAwQFBgkRAQDKmjsAAAAAIKEHAAAAAAA=';
end;

class function TTokenSwapProgramTests.DepositAllTokenTypesMessage: string;
begin
  Result :=
    'AQAEC1MuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft37QqyFDtQcH7hIYXKOEvkCQa+S' +
    'mTK5A6OGMeeZooUoanBBq+hY5sCXEV7zg4lJ8VSwskiFHhDb6/7g31W3nxWVgGqkt1zAcrZOV' +
    'xGCNL6Xm7NI3/Bm+44+nxDHxEdV6rYjoSyYQV+btxvbXHxDsERTxTz2CLMUCdl3qxnNxEiIzGr' +
    'v91zFFZ0BDXh2dnixS0rka8rnVm8/lwluHEzfmVwaq9yV5EkRlspI5dTBei2pTw72+yOOEUXqFwg' +
    'g1djn1hX/FflD5yxhXv/GyRPQxWneSI19VP2k43gUpVYG2jNHwb0E4aXqh2tQhGa5IVDemLCaLk' +
    '5I4fWxHtDzbxweno50Qbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpBqU6rja/SG+12' +
    'TgmTuZF10tgFuD0euuz7BZDi/e/++G/iXGArXvtQXqAznGhXSmATofHCuoBlpHxgPk4SfhBjwEKCg' +
    'cIAAECAwQFBgkZAkBCDwAAAAAAAOh2SBcAAAAA6HZIFwAAAA==';
end;

class function TTokenSwapProgramTests.WithdrawAllTokenTypesMessage: string;
begin
  Result :=
    'AQAEDFMuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft3q7/dcxRWdAQ14dnZ4sUtK5GvK' +
    '51ZvP5cJbhxM35lcGqvcleRJEZbKSOXUwXotqU8O9vsjjhFF6hcIINXY59YVwGqkt1zAcrZOVxGC' +
    'NL6Xm7NI3/Bm+44+nxDHxEdV6rYjoSyYQV+btxvbXHxDsERTxTz2CLMUCdl3qxnNxEiIzHtCrI' +
    'UO1BwfuEhhco4S+QJBr5KZMrkDo4Yx55mihShqcEGr6FjmwJcRXvODiUnxVLCySIUeENvr/uD' +
    'fVbefFZWJespeAcm0TLikLELnMBvM3DxeIdmlTEqtQInQn58Zy78V+UPnLGFe/8bJE9DFad5Ij' +
    'X1U/aTjeBSlVgbaM0fBvQThpeqHa1CEZrkhUN6YsJouTkjh9bEe0PNvHB6ejnRBt324ddloZPZy+' +
    'FGzut5rBy0he1fWzeROoz1hX7/AKkGpTquNr9Ib7XZOCZO5kXXS2AW4PR667PsFkOL97/74RgZ' +
    'qeIKqmWN9s3Opx7A0mQO3EPmMmA+8ndUoI0JQ3gfAQsLCAkAAQIDBAUGBwoZA0BCDwAA' +
    'AAAA6AMAAAAAAADoAwAAAAAAAA==';
end;

class function TTokenSwapProgramTests.DepositSingleTokenTypeExactAmountInMessage: string;
begin
  Result :=
    'AQAEClMuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft37QqyFDtQcH7hIYXKOEvkCQa+' +
    'SmTK5A6OGMeeZooUoakBqpLdcwHK2TlcRgjS+l5uzSN/wZvuOPp8Qx8RHVeq2I6EsmEFfm7c' +
    'b21x8Q7BEU8U89gizFAnZd6sZzcRIiMxq7/dcxRWdAQ14dnZ4sUtK5GvK51ZvP5cJbhxM35lc' +
    'GqvcleRJEZbKSOXUwXotqU8O9vsjjhFF6hcIINXY59YV/xX5Q+csYV7/xskT0MVp3kiNfVT9p' +
    'ON4FKVWBtozR8G9BOGl6odrUIRmuSFQ3piwmi5OSOH1sR7Q828cHp6OdEG3fbh12Whk9nL4' +
    'UbO63msHLSF7V9bN5E6jPWFfv8AqQalOq42v0hvtdk4Jk7mRddLYBbg9Hrrs+wWQ4v3v/vhzr' +
    'NmDrCfcB0Cg6zcl3Vo7qSZvl3ypatPmPfURasFfUABCQkGBwABAgMEBQgRBADKmjsAAAAA6A' +
    'MAAAAAAAA=';
end;

class function TTokenSwapProgramTests.WithdrawSingleTokenTypeExactAmountOutMessage: string;
begin
  Result :=
    'AQAEC1MuM7pUYPM9siiE2WjcHJ6uhumh/A9CE2nvOtqmyft3q7/dcxRWdAQ14dnZ4sUtK5Gv' +
    'K51ZvP5cJbhxM35lcGqvcleRJEZbKSOXUwXotqU8O9vsjjhFF6hcIINXY59YVwGqkt1zAcrZOV' +
    'xGCNL6Xm7NI3/Bm+44+nxDHxEdV6rYjoSyYQV+btxvbXHxDsERTxTz2CLMUCdl3qxnNxEiIz' +
    'HtCrIUO1BwfuEhhco4S+QJBr5KZMrkDo4Yx55mihShqSXrKXgHJtEy4pCxC5zAbzNw8XiHZp' +
    'UxKrUCJ0J+fGcu/FflD5yxhXv/GyRPQxWneSI19VP2k43gUpVYG2jNHwb0E4aXqh2tQhGa5I' +
    'VDemLCaLk5I4fWxHtDzbxweno50Qbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCpBq' +
    'U6rja/SG+12TgmTuZF10tgFuD0euuz7BZDi/e/++G6sYz49vuFr7rLN/dMfUEvpaHxP6DxaNZa' +
    'SUp0zrIUswEKCgcIAAECAwQFBgkRBUBCDwAAAAAAoIYBAAAAAAA=';
end; *)

{ === Builder Tests ========================================================== }

procedure TTokenSwapProgramTests.TestInitialize;
var
  LWallet: IWallet;
  LTokenSwapAccount, LTokenA, LTokenB, LPoolMint, LPoolFee, LPoolToken: IAccount;
  LTx: ITransactionInstruction;
  LFees: IFees;
begin
  LWallet := TWallet.Create(MnemonicWords);

  LTokenSwapAccount := LWallet.GetAccountByIndex(1);
  LTokenA           := LWallet.GetAccountByIndex(3);
  LTokenB           := LWallet.GetAccountByIndex(4);
  LPoolMint         := LWallet.GetAccountByIndex(5);
  LPoolFee          := LWallet.GetAccountByIndex(6);
  LPoolToken        := LWallet.GetAccountByIndex(7);

  LFees := TFees.Create;
  LFees.TradeFeeNumerator              := 1;
  LFees.TradeFeeDenominator            := 100;
  LFees.OwnerWithdrawFeeNumerator       := 0;
  LFees.OwnerWithdrawFeeDenominator       := 1;
  LFees.OwnerTradeFeeDenominator     := 1;
  LFees.OwnerTradeFeeNumerator         := 1;
  LFees.OwnerTradeFeeDenominator       := 100;
  LFees.HostFeeNumerator               := 1;
  LFees.HostFeeDenominator             := 1000;

  LTx := TTokenSwapProgram.Initialize(
    LTokenSwapAccount.PublicKey,
    LTokenA.PublicKey,
    LTokenB.PublicKey,
    LPoolMint.PublicKey,
    LPoolFee.PublicKey,
    LPoolToken.PublicKey,
    LFees,
    TSwapCurve.ConstantProduct
  );

  AssertEquals(8, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(TokenSwapProgramIdBytes, LTx.ProgramId, 'ProgramId');
  AssertEquals(ExpectedInitializeData, LTx.Data, 'Data');
end;

procedure TTokenSwapProgramTests.TestSwap;
var
  LWallet: IWallet;
  LTokenSwapAccount, LUserXfer, LSource, LInto_, LFrom_, LDestination, LPoolTokenMint, LFee, LHostFee: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet := TWallet.Create(MnemonicWords);

  LTokenSwapAccount := LWallet.GetAccountByIndex(1);
  LUserXfer         := LWallet.GetAccountByIndex(3);
  LSource           := LWallet.GetAccountByIndex(4);
  LInto_            := LWallet.GetAccountByIndex(5);
  LFrom_            := LWallet.GetAccountByIndex(6);
  LDestination      := LWallet.GetAccountByIndex(7);
  LPoolTokenMint    := LWallet.GetAccountByIndex(7);
  LFee              := LWallet.GetAccountByIndex(7);
  LHostFee          := LWallet.GetAccountByIndex(7);

  LTx := TTokenSwapProgram.Swap(
    LTokenSwapAccount.PublicKey,
    LUserXfer.PublicKey,
    LSource.PublicKey,
    LInto_.PublicKey,
    LFrom_.PublicKey,
    LDestination.PublicKey,
    LPoolTokenMint.PublicKey,
    LFee.PublicKey,
    LHostFee.PublicKey,
    400000,   // Amount In
    8500000   // Amount Out
  );

  AssertEquals(11, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(TokenSwapProgramIdBytes, LTx.ProgramId, 'ProgramId');
  AssertEquals(ExpectedSwapData, LTx.Data, 'Data');
end;

procedure TTokenSwapProgramTests.TestDepositAllTokenTypes;
var
  LWallet: IWallet;
  LTokenSwapAccount, LUserXfer, LAuthA, LAuthB, LBaseA, LBaseB, LPoolTokenMint, LPoolAccount: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet := TWallet.Create(MnemonicWords);

  LTokenSwapAccount := LWallet.GetAccountByIndex(1);
  LUserXfer         := LWallet.GetAccountByIndex(3);
  LAuthA            := LWallet.GetAccountByIndex(4);
  LAuthB            := LWallet.GetAccountByIndex(5);
  LBaseA            := LWallet.GetAccountByIndex(6);
  LBaseB            := LWallet.GetAccountByIndex(7);
  LPoolTokenMint    := LWallet.GetAccountByIndex(7);
  LPoolAccount      := LWallet.GetAccountByIndex(7);

  LTx := TTokenSwapProgram.DepositAllTokenTypes(
    LTokenSwapAccount.PublicKey,
    LUserXfer.PublicKey,
    LAuthA.PublicKey,
    LAuthB.PublicKey,
    LBaseA.PublicKey,
    LBaseB.PublicKey,
    LPoolTokenMint.PublicKey,
    LPoolAccount.PublicKey,
    4,         // PoolTokens
    8500000,   // MaxTokenA
    4000       // MaxTokenB
  );

  AssertEquals(10, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(TokenSwapProgramIdBytes, LTx.ProgramId, 'ProgramId');
  AssertEquals(ExpectedDepositAllTokenTypesData, LTx.Data, 'Data');
end;

procedure TTokenSwapProgramTests.TestWithdrawAllTokenTypes;
var
  LWallet: IWallet;
  LTokenSwapAccount, LUserXfer, LPoolTokenMint, LSourcePool, LTokenAFrom, LTokenBFrom, LTokenATo, LTokenBTo, LFeeAccount: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet := TWallet.Create(MnemonicWords);

  LTokenSwapAccount := LWallet.GetAccountByIndex(1);
  LUserXfer         := LWallet.GetAccountByIndex(3);
  LPoolTokenMint    := LWallet.GetAccountByIndex(4);
  LSourcePool       := LWallet.GetAccountByIndex(4);
  LTokenAFrom       := LWallet.GetAccountByIndex(5);
  LTokenBFrom       := LWallet.GetAccountByIndex(6);
  LTokenATo         := LWallet.GetAccountByIndex(7);
  LTokenBTo         := LWallet.GetAccountByIndex(7);
  LFeeAccount       := LWallet.GetAccountByIndex(7);

  LTx := TTokenSwapProgram.WithdrawAllTokenTypes(
    LTokenSwapAccount.PublicKey,
    LUserXfer.PublicKey,
    LPoolTokenMint.PublicKey,
    LSourcePool.PublicKey,
    LTokenAFrom.PublicKey,
    LTokenBFrom.PublicKey,
    LTokenATo.PublicKey,
    LTokenBTo.PublicKey,
    LFeeAccount.PublicKey,
    4,        // PoolTokens
    4000,     // MinTokenA
    8500000   // MinTokenB
  );

  AssertEquals(11, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(TokenSwapProgramIdBytes, LTx.ProgramId, 'ProgramId');
  AssertEquals(ExpectedWithdrawAllTokenTypesData, LTx.Data, 'Data');
end;

procedure TTokenSwapProgramTests.TestDepositSingleTokenTypeExactAmountInTypes;
var
  LWallet: IWallet;
  LTokenSwapAccount, LUserXfer, LTokenSource, LTokenA, LTokenB, LPoolMint, LPool: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet := TWallet.Create(MnemonicWords);

  LTokenSwapAccount := LWallet.GetAccountByIndex(1);
  LUserXfer         := LWallet.GetAccountByIndex(3);
  LTokenSource      := LWallet.GetAccountByIndex(4);
  LTokenA           := LWallet.GetAccountByIndex(5);
  LTokenB           := LWallet.GetAccountByIndex(6);
  LPoolMint         := LWallet.GetAccountByIndex(7);
  LPool             := LWallet.GetAccountByIndex(7);

  LTx := TTokenSwapProgram.DepositSingleTokenTypeExactAmountIn(
    LTokenSwapAccount.PublicKey,
    LUserXfer.PublicKey,
    LTokenSource.PublicKey,
    LTokenA.PublicKey,
    LTokenB.PublicKey,
    LPoolMint.PublicKey,
    LPool.PublicKey,
    4000,  // Source Token Amount
    4      // Min Pool Token Amount
  );

  AssertEquals(9, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(TokenSwapProgramIdBytes, LTx.ProgramId, 'ProgramId');
  AssertEquals(ExpectedDepositSingleTokenTypeExactAmountInData, LTx.Data, 'Data');
end;

procedure TTokenSwapProgramTests.TestWithdrawSingleTokenTypeExactAmountOutTypes;
var
  LWallet: IWallet;
  LTokenSwapAccount, LUserXfer, LPoolMint, LSourcePool, LTokenASource, LTokenBSource, LUserToken, LFeeAccount: IAccount;
  LTx: ITransactionInstruction;
begin
  LWallet := TWallet.Create(MnemonicWords);

  LTokenSwapAccount := LWallet.GetAccountByIndex(1);
  LUserXfer         := LWallet.GetAccountByIndex(3);
  LPoolMint         := LWallet.GetAccountByIndex(4);
  LSourcePool       := LWallet.GetAccountByIndex(5);
  LTokenASource     := LWallet.GetAccountByIndex(6);
  LTokenBSource     := LWallet.GetAccountByIndex(6);
  LUserToken        := LWallet.GetAccountByIndex(7);
  LFeeAccount       := LWallet.GetAccountByIndex(7);

  LTx := TTokenSwapProgram.WithdrawSingleTokenTypeExactAmountOut(
    LTokenSwapAccount.PublicKey,
    LUserXfer.PublicKey,
    LPoolMint.PublicKey,
    LSourcePool.PublicKey,
    LTokenASource.PublicKey,
    LTokenBSource.PublicKey,
    LUserToken.PublicKey,
    LFeeAccount.PublicKey,
    4000,  // Destination Token Amount
    4      // Max Pool Token Amount
  );

  AssertEquals(10, LTx.Keys.Count, 'Keys.Count');
  AssertEquals(TokenSwapProgramIdBytes, LTx.ProgramId, 'ProgramId');
  AssertEquals(ExpectedWithdrawSingleTokenTypeExactAmountOutData,  LTx.Data, 'Data');
end;

{ === Decode Tests (value-by-value + Free the list) ========================= }

procedure TTokenSwapProgramTests.InitializeDecodeTest;
var
  LMsg: IMessage;
  LDecoded: TList<IDecodedInstruction>;
  LVal: TValue;
begin
  LMsg      := TMessage.Deserialize(InitializeMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(2, LDecoded.Count, 'Count');

    // [0] System: Create Account
    AssertEquals('Create Account',  LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('System Program',  LDecoded[0].ProgramName,     'I0 program');
    AssertTrue(LDecoded[0].Values.TryGetValue('Owner Account', LVal), 'I0 missing "Owner Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('New Account',   LVal), 'I0 missing "New Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Amount',        LVal), 'I0 missing "Amount"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Space',         LVal), 'I0 missing "Space"');

    // [1] Token Swap: Initialize Swap
    AssertEquals('Initialize Swap',    LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('Token Swap Program', LDecoded[1].ProgramName,     'I1 program');

    AssertTrue(LDecoded[1].Values.TryGetValue('Token Swap Account', LVal), 'Missing "Token Swap Account"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Swap Authority',     LVal), 'Missing "Swap Authority"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Token A Account',    LVal), 'Missing "Token A Account"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Token B Account',    LVal), 'Missing "Token B Account"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Pool Token Mint',    LVal), 'Missing "Pool Token Mint"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Pool Token Fee Account', LVal), 'Missing "Pool Token Fee Account"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Pool Token Account', LVal), 'Missing "Pool Token Account"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Token Program ID',   LVal), 'Missing "Token Program ID"');

    AssertTrue(LDecoded[1].Values.TryGetValue('Nonce',                        LVal), 'Missing "Nonce"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Trade Fee Numerator',          LVal), 'Missing "Trade Fee Numerator"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Trade Fee Denominator',        LVal), 'Missing "Trade Fee Denominator"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Owner Trade Fee Numerator',    LVal), 'Missing "Owner Trade Fee Numerator"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Owner Trade Fee Denominator',  LVal), 'Missing "Owner Trade Fee Denominator"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Owner Withraw Fee Numerator',  LVal), 'Missing "Owner Withraw Fee Numerator"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Owner Withraw Fee Denominator',LVal), 'Missing "Owner Withraw Fee Denominator"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Host Fee Numerator',           LVal), 'Missing "Host Fee Numerator"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Host Fee Denominator',         LVal), 'Missing "Host Fee Denominator"');
    AssertTrue(LDecoded[1].Values.TryGetValue('Curve Type',                   LVal), 'Missing "Curve Type"');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenSwapProgramTests.SwapDecodeTest;
var
  LMsg: IMessage;
  LDecoded: TList<IDecodedInstruction>;
  LVal: TValue;
begin
  LMsg      := TMessage.Deserialize(SwapMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(1, LDecoded.Count, 'Count');
    AssertEquals('Swap',              LDecoded[0].InstructionName, 'name');
    AssertEquals('Token Swap Program',LDecoded[0].ProgramName,     'program');

    AssertTrue(LDecoded[0].Values.TryGetValue('Token Swap Account', LVal), 'Missing "Token Swap Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Swap Authority',     LVal), 'Missing "Swap Authority"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Transfer Authority', LVal), 'Missing "User Transfer Authority"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Source Account', LVal), 'Missing "User Source Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Token Base Into Account', LVal), 'Missing "Token Base Into Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Token Base From Account', LVal), 'Missing "Token Base From Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Destination Account', LVal), 'Missing "User Destination Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Pool Token Mint', LVal), 'Missing "Pool Token Mint"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Fee Account', LVal), 'Missing "Fee Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Token Program ID', LVal), 'Missing "Token Program ID"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Amount In',  LVal), 'Missing "Amount In"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Amount Out', LVal), 'Missing "Amount Out"');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenSwapProgramTests.DepositAllTokenTypesDecodeTest;
var
  LMsg: IMessage;
  LDecoded: TList<IDecodedInstruction>;
  LVal: TValue;
begin
  LMsg      := TMessage.Deserialize(DepositAllTokenTypesMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(1, LDecoded.Count, 'Count');
    AssertEquals('Deposit Both',     LDecoded[0].InstructionName, 'name');
    AssertEquals('Token Swap Program',LDecoded[0].ProgramName,    'program');

    AssertTrue(LDecoded[0].Values.TryGetValue('Token Swap Account', LVal), 'Missing "Token Swap Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Swap Authority',     LVal), 'Missing "Swap Authority"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Transfer Authority', LVal), 'Missing "User Transfer Authority"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Token A Account', LVal), 'Missing "User Token A Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Token B Account', LVal), 'Missing "User Token B Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Pool Token A Account', LVal), 'Missing "Pool Token A Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Pool Token B Account', LVal), 'Missing "Pool Token B Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Pool Token Mint', LVal), 'Missing "Pool Token Mint"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Pool Token Account', LVal), 'Missing "User Pool Token Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Token Program ID', LVal), 'Missing "Token Program ID"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Pool Tokens', LVal), 'Missing "Pool Tokens"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Max Token A', LVal), 'Missing "Max Token A"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Max Token B', LVal), 'Missing "Max Token B"');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenSwapProgramTests.WithdrawAllTokenTypesDecodeTest;
var
  LMsg: IMessage;
  LDecoded: TList<IDecodedInstruction>;
  LVal: TValue;
begin
  LMsg      := TMessage.Deserialize(WithdrawAllTokenTypesMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(1, LDecoded.Count, 'Count');
    AssertEquals('Withdraw Both',     LDecoded[0].InstructionName, 'name');
    AssertEquals('Token Swap Program',LDecoded[0].ProgramName,     'program');

    AssertTrue(LDecoded[0].Values.TryGetValue('Token Swap Account', LVal), 'Missing "Token Swap Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Swap Authority',     LVal), 'Missing "Swap Authority"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Transfer Authority', LVal), 'Missing "User Transfer Authority"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Pool Token Account', LVal), 'Missing "Pool Token Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Pool Token Account', LVal), 'Missing "User Pool Token Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Pool Token A Account', LVal), 'Missing "Pool Token A Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Pool Token B Account', LVal), 'Missing "Pool Token B Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Token A Account', LVal), 'Missing "User Token A Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Token B Account', LVal), 'Missing "User Token B Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Fee Account', LVal), 'Missing "Fee Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Token Program ID', LVal), 'Missing "Token Program ID"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Pool Tokens', LVal), 'Missing "Pool Tokens"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Min Token A', LVal), 'Missing "Min Token A"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Min Token B', LVal), 'Missing "Min Token B"');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenSwapProgramTests.DepositSingleTokenTypeExactAmountInDecodeTest;
var
  LMsg: IMessage;
  LDecoded: TList<IDecodedInstruction>;
  LVal: TValue;
begin
  LMsg      := TMessage.Deserialize(DepositSingleTokenTypeExactAmountInMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(1, LDecoded.Count, 'Count');
    AssertEquals('Deposit Single',     LDecoded[0].InstructionName, 'name');
    AssertEquals('Token Swap Program', LDecoded[0].ProgramName,     'program');

    AssertTrue(LDecoded[0].Values.TryGetValue('Token Swap Account', LVal), 'Missing "Token Swap Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Swap Authority',     LVal), 'Missing "Swap Authority"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Transfer Authority', LVal), 'Missing "User Transfer Authority"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Source Token Account', LVal), 'Missing "User Source Token Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Token A Swap Account', LVal), 'Missing "Token A Swap Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Token B Swap Account', LVal), 'Missing "Token B Swap Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Pool Mint Account',   LVal), 'Missing "Pool Mint Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Pool Token Account', LVal), 'Missing "User Pool Token Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Token Program ID',    LVal), 'Missing "Token Program ID"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Source Token Amount', LVal), 'Missing "Source Token Amount"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Min Pool Token Amount', LVal), 'Missing "Min Pool Token Amount"');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenSwapProgramTests.WithdrawSingleTokenTypeExactAmountOutDecodeTest;
var
  LMsg: IMessage;
  LDecoded: TList<IDecodedInstruction>;
  LVal: TValue;
begin
  LMsg      := TMessage.Deserialize(WithdrawSingleTokenTypeExactAmountOutMessage);
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    AssertEquals(1, LDecoded.Count, 'Count');
    AssertEquals('Withdraw Single',   LDecoded[0].InstructionName, 'name');
    AssertEquals('Token Swap Program',LDecoded[0].ProgramName,     'program');

    AssertTrue(LDecoded[0].Values.TryGetValue('Token Swap Account', LVal), 'Missing "Token Swap Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Swap Authority',     LVal), 'Missing "Swap Authority"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Transfer Authority', LVal), 'Missing "User Transfer Authority"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Pool Mint Account',  LVal), 'Missing "Pool Mint Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Pool Token Account', LVal), 'Missing "User Pool Token Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Token A Swap Account', LVal), 'Missing "Token A Swap Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Token B Swap Account', LVal), 'Missing "Token B Swap Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('User Token Account',  LVal), 'Missing "User Token Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Fee Account',         LVal), 'Missing "Fee Account"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Token Program ID',    LVal), 'Missing "Token Program ID"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Destination Token Amount', LVal), 'Missing "Destination Token Amount"');
    AssertTrue(LDecoded[0].Values.TryGetValue('Max Pool Token Amount', LVal), 'Missing "Max Pool Token Amount"');
  finally
    LDecoded.Free;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TTokenSwapProgramTests);
{$ELSE}
  RegisterTest(TTokenSwapProgramTests.Suite);
{$ENDIF}

end.

