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
  LMsg: IMessage;
begin
  LMsg := TMessage.Deserialize(Base64Message);

  // Header
  AssertNotNull(LMsg);
  AssertEquals(2, LMsg.Header.RequiredSignatures);
  AssertEquals(0, LMsg.Header.ReadOnlySignedAccounts);
  AssertEquals(4, LMsg.Header.ReadOnlyUnsignedAccounts);

  // Blockhash
  AssertEquals('GDgnjNiNGnw9nA3diFYKeizi8LpBzFMjDaBSU5hoqEUH', LMsg.RecentBlockhash);

  // Account keys
  AssertEquals(6, LMsg.AccountKeys.Count);
  AssertEquals('7y62LXLwANaN9g3KJPxQFYwMxSdZraw5PkqwtqY9zLDF', LMsg.AccountKeys[0].Key);
  AssertEquals('FWUPMzrLbAEuH83cf1QphoFdyUdhenDF5oHftwd9Vjyr', LMsg.AccountKeys[1].Key);
  AssertEquals('AN5M7KvEFiZFxgEUWFdZUdR5i4b96HjXawADpqjxjXCL', LMsg.AccountKeys[2].Key);
  AssertEquals('SysvarRent111111111111111111111111111111111',   LMsg.AccountKeys[3].Key);
  AssertEquals('11111111111111111111111111111111',             LMsg.AccountKeys[4].Key);
  AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA',  LMsg.AccountKeys[5].Key);

  // Instructions
  AssertEquals(2, LMsg.Instructions.Count);

  // Instruction 0
  AssertEquals(4, LMsg.Instructions[0].ProgramIdIndex);
  AssertEquals(LMsg.Instructions[0].KeyIndices,      TBytes.Create(0, 1));
  AssertEquals(LMsg.Instructions[0].KeyIndicesCount, TBytes.Create(2));
  AssertEquals(LMsg.Instructions[0].DataLength,      TBytes.Create(52));
  AssertEquals(
    LMsg.Instructions[0].Data,
    TBytes.Create(
      0,0,0,0,240,29,31,0,0,0,0,0,165,0,0,0,0,0,0,0,
      6,221,246,225,215,101,161,147,217,203,225,70,206,235,121,172,28,180,
      133,237,95,91,55,145,58,140,245,133,126,255,0,169
    )
  );

  // Instruction 1
  AssertEquals(5, LMsg.Instructions[1].ProgramIdIndex);
  AssertEquals(LMsg.Instructions[1].KeyIndices,      TBytes.Create(1, 2, 0, 3));
  AssertEquals(LMsg.Instructions[1].KeyIndicesCount, TBytes.Create(4));
  AssertEquals(LMsg.Instructions[1].DataLength,      TBytes.Create(1));
  AssertEquals(LMsg.Instructions[1].Data,            TBytes.Create(1));
end;

procedure TMessageTests.MessageSerializeTest;
var
  LMsg: IMessage;
  LC0, LC1: ICompiledInstruction;
  LMessageBytes, LSer: TBytes;
begin
  LMessageBytes := TBytes.Create(
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

  LMsg := TMessage.Create;
  LMsg.Header := TMessageHeader.Create;
  LMsg.Header.RequiredSignatures := 2;
  LMsg.Header.ReadOnlySignedAccounts := 0;
  LMsg.Header.ReadOnlyUnsignedAccounts := 4;

  LMsg.RecentBlockhash := '6dpApBv7syEswXqBMkyHqETN3MGY5x4ZW2cnLzRSSLJ4';

  // Accounts
  LMsg.AccountKeys := TList<IPublicKey>.Create;
  LMsg.AccountKeys.AddRange([
    TPublicKey.Create('7y62LXLwANaN9g3KJPxQFYwMxSdZraw5PkqwtqY9zLDF'),
    TPublicKey.Create('BEQZbsAdm5tRgtezK65oFgQwYanujpxx96jYo7Nkp592'),
    TPublicKey.Create('AN5M7KvEFiZFxgEUWFdZUdR5i4b96HjXawADpqjxjXCL'),
    TPublicKey.Create('SysvarRent111111111111111111111111111111111'),
    TPublicKey.Create('11111111111111111111111111111111'),
    TPublicKey.Create('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA')
  ]);

  // Compiled Instructions
  LMsg.Instructions := TList<ICompiledInstruction>.Create;

  // Instruction 0
  LC0 := TCompiledInstruction.Create(
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
  LMsg.Instructions.Add(LC0);

  // Instruction 1
  LC1 := TCompiledInstruction.Create(
          5,
          TBytes.Create(4),
          TBytes.Create(1, 2, 0, 3),
          TBytes.Create(1),
          TBytes.Create(1)
        );
  LMsg.Instructions.Add(LC1);

  // Serialize and verify
  LSer := LMsg.Serialize;
  AssertEquals(LSer, LMessageBytes, 'Serialized message bytes mismatch');
end;

initialization
{$IFDEF FPC}
  RegisterTest(TMessageTests);
{$ELSE}
  RegisterTest(TMessageTests.Suite);
{$ENDIF}

end.

