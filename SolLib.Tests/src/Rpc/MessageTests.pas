{ * ************************************************************************ * }
{ *                              SolLib Library                              * }
{ *                  Copyright (c) 2025 Ugochukwu Mmaduekwe                  * }
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

unit MessageTests;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpPublicKey,
  SlpMessageDomain,
  SlpTransactionInstruction,
  SolLibTestCase;

type
  TMessageTests = class(TSolLibTestCase)
  published
    procedure MessageDeserializeTest;
    procedure MessageSerializeTest;
  end;

implementation

{ TMessageTests }

procedure TMessageTests.MessageDeserializeTest;
const
  Base64Message =
    'AgAEBmeEU5GowlV7Ug3Y0gjKv+31fvJ5iq+FC+pj+blJfEu615Bs5Vo6mnXZXvh35ULmThtyhwH8xzDk8CgGqB1ISymLH0tOe6K/10n8jVYmg9CCzfFJ7Q/' +
    'PtKWCWZjI/MJBiQan1RcZLFxRIYzJTD1K8X9Y2u4Im6H9ROPb2YoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAG3fbh12Whk9nL4UbO63m' +
    'sHLSF7V9bN5E6jPWFfv8AqeIfQzb6ERv8S2AqP3kpqFe1rhOi8a8q+HoB5Z/4WUfiAgQCAAE0AAAAAPAdHwAAAAAApQAAAAAAAAAG3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqQUEAQIAAwEB';
var
  Msg: IMessage;
begin
  Msg := TMessage.Deserialize(Base64Message);

  // Header
  AssertNotNull(Msg);
  AssertEquals(2, Msg.Header.RequiredSignatures);
  AssertEquals(0, Msg.Header.ReadOnlySignedAccounts);
  AssertEquals(4, Msg.Header.ReadOnlyUnsignedAccounts);

  // Blockhash
  AssertEquals('GDgnjNiNGnw9nA3diFYKeizi8LpBzFMjDaBSU5hoqEUH', Msg.RecentBlockhash);

  // Account keys
  AssertEquals(6, Msg.AccountKeys.Count);
  AssertEquals('7y62LXLwANaN9g3KJPxQFYwMxSdZraw5PkqwtqY9zLDF', Msg.AccountKeys[0].Key);
  AssertEquals('FWUPMzrLbAEuH83cf1QphoFdyUdhenDF5oHftwd9Vjyr', Msg.AccountKeys[1].Key);
  AssertEquals('AN5M7KvEFiZFxgEUWFdZUdR5i4b96HjXawADpqjxjXCL', Msg.AccountKeys[2].Key);
  AssertEquals('SysvarRent111111111111111111111111111111111',   Msg.AccountKeys[3].Key);
  AssertEquals('11111111111111111111111111111111',             Msg.AccountKeys[4].Key);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA',  Msg.AccountKeys[5].Key);

  // Instructions
  AssertEquals(2, Msg.Instructions.Count);

  // Instruction 0
  AssertEquals(4, Msg.Instructions[0].ProgramIdIndex);
  AssertEquals<Byte>(Msg.Instructions[0].KeyIndices,      TBytes.Create(0, 1));
  AssertEquals<Byte>(Msg.Instructions[0].KeyIndicesCount, TBytes.Create(2));
  AssertEquals<Byte>(Msg.Instructions[0].DataLength,      TBytes.Create(52));
  AssertEquals<Byte>(
    Msg.Instructions[0].Data,
    TBytes.Create(
      0,0,0,0,240,29,31,0,0,0,0,0,165,0,0,0,0,0,0,0,
      6,221,246,225,215,101,161,147,217,203,225,70,206,235,121,172,28,180,
      133,237,95,91,55,145,58,140,245,133,126,255,0,169
    )
  );

  // Instruction 1
  AssertEquals(5, Msg.Instructions[1].ProgramIdIndex);
  AssertEquals<Byte>(Msg.Instructions[1].KeyIndices,      TBytes.Create(1, 2, 0, 3));
  AssertEquals<Byte>(Msg.Instructions[1].KeyIndicesCount, TBytes.Create(4));
  AssertEquals<Byte>(Msg.Instructions[1].DataLength,      TBytes.Create(1));
  AssertEquals<Byte>(Msg.Instructions[1].Data,            TBytes.Create(1));
end;

procedure TMessageTests.MessageSerializeTest;
var
  Msg: IMessage;
  C0, C1: ICompiledInstruction;
  MessageBytes, Ser: TBytes;
begin
  MessageBytes := TBytes.Create(
    2,0,4,6,103,132,83,145,168,194,85,123,82,13,216,210,8,202,191,237,245,126,242,
    121,138,175,133,11,234,99,249,185,73,124,75,186,152,4,15,191,192,69,38,242,209,25,
    50,6,106,251,40,228,145,75,129,20,113,52,100,202,150,100,146,135,243,11,171,9,139,
    31,75,78,123,162,191,215,73,252,141,86,38,131,208,130,205,241,73,237,15,207,180,
    165,130,89,152,200,252,194,65,137,6,167,213,23,25,44,92,81,33,140,201,76,61,74,
    241,127,88,218,238,8,155,161,253,68,227,219,217,138,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,221,246,225,215,101,161,
    147,217,203,225,70,206,235,121,172,28,180,133,237,95,91,55,145,58,140,245,133,126,
    255,0,169,83,184,173,154,195,40,140,119,87,191,63,56,94,10,92,101,22,75,177,41,
    209,154,164,40,179,236,193,222,193,120,75,193,2,4,2,0,1,52,0,0,0,0,240,29,31,0,
    0,0,0,0,165,0,0,0,0,0,0,0,6,221,246,225,215,101,161,147,217,203,225,70,206,235,
    121,172,28,180,133,237,95,91,55,145,58,140,245,133,126,255,0,169,5,4,1,2,0,3,1,1
  );

  Msg := TMessage.Create;
  Msg.Header := TMessageHeader.Create;
  Msg.Header.RequiredSignatures := 2;
  Msg.Header.ReadOnlySignedAccounts := 0;
  Msg.Header.ReadOnlyUnsignedAccounts := 4;

  Msg.RecentBlockhash := '6dpApBv7syEswXqBMkyHqETN3MGY5x4ZW2cnLzRSSLJ4';

  // Accounts
  Msg.AccountKeys := TList<IPublicKey>.Create;
  Msg.AccountKeys.AddRange([
    TPublicKey.Create('7y62LXLwANaN9g3KJPxQFYwMxSdZraw5PkqwtqY9zLDF'),
    TPublicKey.Create('BEQZbsAdm5tRgtezK65oFgQwYanujpxx96jYo7Nkp592'),
    TPublicKey.Create('AN5M7KvEFiZFxgEUWFdZUdR5i4b96HjXawADpqjxjXCL'),
    TPublicKey.Create('SysvarRent111111111111111111111111111111111'),
    TPublicKey.Create('11111111111111111111111111111111'),
    TPublicKey.Create('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA')
  ]);

  // Compiled Instructions
  Msg.Instructions := TList<ICompiledInstruction>.Create;

  // Instruction 0
  C0 := TCompiledInstruction.Create(
          4,
          TBytes.Create(2),
          TBytes.Create(0, 1),
          TBytes.Create(52),
          TBytes.Create(
            0,0,0,0,240,29,31,0,0,0,0,0,165,0,0,0,0,0,0,0,
            6,221,246,225,215,101,161,147,217,203,225,70,206,235,121,172,28,180,
            133,237,95,91,55,145,58,140,245,133,126,255,0,169
          )
        );
  Msg.Instructions.Add(C0);

  // Instruction 1
  C1 := TCompiledInstruction.Create(
          5,
          TBytes.Create(4),
          TBytes.Create(1, 2, 0, 3),
          TBytes.Create(1),
          TBytes.Create(1)
        );
  Msg.Instructions.Add(C1);

  // Serialize and verify
  Ser := Msg.Serialize;
  AssertEquals<Byte>(Ser, MessageBytes, 'Serialized message bytes mismatch');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TMessageTests);
{$ELSE}
  RegisterTest(TMessageTests.Suite);
{$ENDIF}

end.

