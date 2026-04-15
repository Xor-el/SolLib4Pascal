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

unit SlpMnemonic;

{$I ../../Include/SolLib.inc}

interface

uses
  SysUtils,
  Classes,
  SlpWordList,
  SlpWalletEnum,
  SlpNullable,
  SlpCryptoUtilities,
  SlpBitWriter,
  SlpArrayUtilities,
  SlpKdTable,
  SlpSolLibTypes;

type
  IMnemonic = interface
    ['{38F2E4E6-4D67-4E86-9B0F-6E5B6A7A0E21}']
    function IsValidChecksum: Boolean;
    function DeriveSeed(const APassphrase: string = ''): TBytes;

    function GetWordList: IWordList;
    function GetIndices: TArray<Integer>;
    function GetWords: TArray<string>;

    function ToString: string;

    property WordList: IWordList read GetWordList;
    property Indices: TArray<Integer> read GetIndices;
    property Words: TArray<string> read GetWords;
  end;

  TMnemonic = class(TInterfacedObject, IMnemonic)
  private
    type
      /// <summary>
      /// Encapsulates the relationship between word count, checksum bits,
      /// and entropy bits for a single BIP39 strength level.
      /// </summary>
      TMnemonicSpec = record
        WordCount: Integer;
        ChecksumBits: Integer;
        EntropyBits: Integer;
      end;

    const
      /// <summary>
      /// BIP39 strength levels: 12/15/18/21/24 words.
      /// Word count = (entropy + checksum) / 11, where checksum = entropy / 32.
      /// </summary>
      Specs: array[0..4] of TMnemonicSpec = (
        (WordCount: 12; ChecksumBits: 4; EntropyBits: 128),
        (WordCount: 15; ChecksumBits: 5; EntropyBits: 160),
        (WordCount: 18; ChecksumBits: 6; EntropyBits: 192),
        (WordCount: 21; ChecksumBits: 7; EntropyBits: 224),
        (WordCount: 24; ChecksumBits: 8; EntropyBits: 256)
      );

      /// <summary>Whitespace characters used to split mnemonic sentences.</summary>
      WhitespaceSeparators: array[0..12] of Char = (
        Char($0009),  // TAB
        Char($000A),  // LF
        Char($000B),  // VT
        Char($000C),  // FF
        Char($000D),  // CR
        Char($0020),  // SPACE
        Char($00A0),  // NBSP
        Char($0085),  // NEL
        Char($1680),  // OGHAM SPACE MARK
        Char($2000),  // EN QUAD
        Char($2001),  // EM QUAD
        Char($2002),  // EN SPACE
        Char($3000)   // IDEOGRAPHIC SPACE
      );

      /// <summary>PBKDF2 iteration count for seed derivation (BIP39).</summary>
      SeedIterations = 2048;
      /// <summary>Derived seed length in bytes (BIP39).</summary>
      SeedLength = 64;

    var
      FWordList: IWordList;
      FIndices: TArray<Integer>;
      FWords: TArray<string>;
      FMnemonic: string;
      FIsValidChecksum: TNullable<Boolean>;

    function GetWordList: IWordList;
    function GetIndices: TArray<Integer>;
    function GetWords: TArray<string>;
    function IsValidChecksum: Boolean;
    function DeriveSeed(const APassphrase: string = ''): TBytes;

    /// <summary>
    /// Finds the TMnemonicSpec matching the given word count.
    /// Returns True if found, with ASpec set accordingly.
    /// </summary>
    class function TryFindSpec(AWordCount: Integer; out ASpec: TMnemonicSpec): Boolean; static;

    /// <summary>
    /// Finds the TMnemonicSpec matching the given entropy bit length.
    /// Returns True if found, with ASpec set accordingly.
    /// </summary>
    class function TryFindSpecByEntropy(AEntropyBits: Integer; out ASpec: TMnemonicSpec): Boolean; static;

    /// <summary>
    /// Returns the NFKD-normalized UTF-8 encoding of AInput.
    /// </summary>
    class function NormalizeUTF8(const AInput: string): TBytes; static;

    /// <summary>Generate entropy for the given word count.</summary>
    class function GenerateEntropy(AWordCount: TWordCount): TBytes; static;

    /// <summary>Generate a mnemonic from entropy.</summary>
    constructor CreateFromEntropy(AWordList: IWordList; AEntropy: TBytes = nil); overload;
  public
    /// <summary>
    /// Initialize a mnemonic from the given string and optional wordlist.
    /// Auto-detects language if AWordList is nil.
    /// </summary>
    constructor Create(const AMnemonic: string; AWordList: IWordList = nil); overload;

    /// <summary>
    /// Generate a new mnemonic with the given word list and word count.
    /// </summary>
    constructor Create(AWordList: IWordList; AWordCount: TWordCount); overload;

    function ToString: string; override;

    /// <summary>NFKD normalization of the input string.</summary>
    class function NormalizeString(const AInput: string): string; static;
  end;

implementation

{ TMnemonic }

class function TMnemonic.TryFindSpec(AWordCount: Integer;
  out ASpec: TMnemonicSpec): Boolean;
var
  LI: Integer;
begin
  for LI := Low(Specs) to High(Specs) do
    if Specs[LI].WordCount = AWordCount then
    begin
      ASpec := Specs[LI];
      Exit(True);
    end;
  ASpec := Default(TMnemonicSpec);
  Result := False;
end;

class function TMnemonic.TryFindSpecByEntropy(AEntropyBits: Integer;
  out ASpec: TMnemonicSpec): Boolean;
var
  LI: Integer;
begin
  for LI := Low(Specs) to High(Specs) do
    if Specs[LI].EntropyBits = AEntropyBits then
    begin
      ASpec := Specs[LI];
      Exit(True);
    end;
  ASpec := Default(TMnemonicSpec);
  Result := False;
end;

constructor TMnemonic.Create(const AMnemonic: string; AWordList: IWordList);
var
  LWL: IWordList;
  LWordsSplit: TArray<string>;
  LSpec: TMnemonicSpec;
begin
  if AMnemonic = '' then
    raise EArgumentNilException.Create('mnemonic');

  FMnemonic := Trim(AMnemonic);

  // Resolve wordlist: auto-detect from sentence, fallback to English
  if AWordList = nil then
  begin
    LWL := TWordList.AutoDetect(FMnemonic);
    if LWL = nil then
      LWL := TWordList.English;
  end
  else
    LWL := AWordList;

  // Split on all recognized whitespace
  LWordsSplit := FMnemonic.Split(WhitespaceSeparators, TStringSplitOptions.ExcludeEmpty);

  if not TryFindSpec(Length(LWordsSplit), LSpec) then
    raise EArgumentException.Create('Word count should be 12, 15, 18, 21 or 24');

  // Re-join with the wordlist's canonical separator
  FMnemonic := string.Join(LWL.Space, LWordsSplit);
  FWords := LWordsSplit;
  FWordList := LWL;
  FIndices := LWL.ToIndices(FWords);
  FIsValidChecksum := TNullable<Boolean>.None;
end;

constructor TMnemonic.CreateFromEntropy(AWordList: IWordList; AEntropy: TBytes);
var
  LWL: IWordList;
  LSpec: TMnemonicSpec;
  LChecksum: TBytes;
  LWriter: TBitWriter;
begin
  if AWordList = nil then
    LWL := TWordList.English
  else
    LWL := AWordList;

  if AEntropy = nil then
    AEntropy := TRandom.RandomBytes(32);

  if not TryFindSpecByEntropy(Length(AEntropy) * 8, LSpec) then
    raise EArgumentException.Create(
      'Entropy length should be 128, 160, 192, 224 or 256 bits');

  FWordList := LWL;

  LChecksum := TSHA256.HashData(AEntropy);

  LWriter := TBitWriter.Create;
  try
    LWriter.Write(AEntropy);
    LWriter.Write(LChecksum, LSpec.ChecksumBits);
    FIndices := LWriter.ToIntegers();
  finally
    LWriter.Free;
  end;

  FWords := LWL.GetWordsByIndices(FIndices);
  FMnemonic := LWL.GetSentence(FIndices);
  FIsValidChecksum := TNullable<Boolean>.None;
end;

constructor TMnemonic.Create(AWordList: IWordList; AWordCount: TWordCount);
begin
  CreateFromEntropy(AWordList, GenerateEntropy(AWordCount));
end;

class function TMnemonic.GenerateEntropy(AWordCount: TWordCount): TBytes;
var
  LSpec: TMnemonicSpec;
begin
  if not TryFindSpec(Ord(AWordCount), LSpec) then
    raise EArgumentException.Create('Word count should be 12, 15, 18, 21 or 24');
  Result := TRandom.RandomBytes(LSpec.EntropyBits div 8);
end;

function TMnemonic.GetIndices: TArray<Integer>;
begin
  Result := FIndices;
end;

function TMnemonic.GetWordList: IWordList;
begin
  Result := FWordList;
end;

function TMnemonic.GetWords: TArray<string>;
begin
  Result := FWords;
end;

class function TMnemonic.NormalizeString(const AInput: string): string;
begin
  Result := TKdTable.NormalizeKd(AInput);
end;

class function TMnemonic.NormalizeUTF8(const AInput: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(NormalizeString(AInput));
end;

function TMnemonic.IsValidChecksum: Boolean;
var
  LSpec: TMnemonicSpec;
  LBits: TBits;
  LWriter: TBitWriter;
  LEntropy, LChecksum: TBytes;
  LExpectedIndices: TArray<Integer>;
begin
  if FIsValidChecksum.HasValue then
    Exit(FIsValidChecksum.Value);

  if not TryFindSpec(Length(FIndices), LSpec) then
  begin
    FIsValidChecksum := False;
    Exit(False);
  end;

  LWriter := TBitWriter.Create;
  try
    LBits := TWordList.ToBits(FIndices);
    try
      LWriter.Write(LBits, LSpec.EntropyBits);
    finally
      LBits.Free;
    end;

    LEntropy := LWriter.ToBytes();
    LChecksum := TSHA256.HashData(LEntropy);

    LWriter.Write(LChecksum, LSpec.ChecksumBits);
    LExpectedIndices := LWriter.ToIntegers();
  finally
    LWriter.Free;
  end;

  FIsValidChecksum := TArrayUtilities.AreArraysEqual(LExpectedIndices, FIndices);
  Result := FIsValidChecksum.Value;
end;

function TMnemonic.DeriveSeed(const APassphrase: string): TBytes;
var
  LSalt, LPW: TBytes;
begin
  LPW := NormalizeUTF8(FMnemonic);
  // salt = "mnemonic" || NFKD(passphrase)
  LSalt := TArrayUtilities.Concat<Byte>(
    TEncoding.UTF8.GetBytes('mnemonic'),
    NormalizeUTF8(APassphrase)
  );
  Result := TPbkdf2SHA512.DeriveKey(LPW, LSalt, SeedIterations, SeedLength);
end;

function TMnemonic.ToString: string;
begin
  Result := FMnemonic;
end;

end.
