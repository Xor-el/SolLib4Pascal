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

unit SlpFlag;

{$I ..\..\SolLib\src\Include\SolLib.inc}

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Represents bitmask flags for various types of accounts within Solana Programs.
  /// </summary>
  /// <typeparam name="T">The underlying unsigned integral type.</typeparam>
  IFlag<T> = interface
    ['{C3B6E3E1-2F4C-4E86-A9E2-6E8F0D2F9E26}']
    /// <summary>
    /// The mask for the account flags.
    /// </summary>
    function GetValue: T;

    /// <summary>
    /// The mask for the account flags.
    /// </summary>
    property Value: T read GetValue;
  end;

  /// <summary>
  /// Represents bitmask flags for various types of accounts within Solana Programs.
  /// </summary>
  /// <typeparam name="T">The underlying unsigned integral type.</typeparam>
  TFlag<T> = class abstract(TInterfacedObject, IFlag<T>)
  strict private
    FValue: T;

    /// <summary>
    /// The mask for the account flags.
    /// </summary>
    function GetValue: T;
  strict protected

    property Value: T read GetValue;

    /// <summary>
    /// Checks whether the Kth bit for a given number N is set.
    /// </summary>
    /// <param name="AN">The number to check against.</param>
    /// <param name="AK">The bit to check (1-based).</param>
    /// <returns>true if it is, otherwise false.</returns>
    class function IsKthBitSet(const AN: UInt64; const AK: Integer): Boolean; static; inline;
  public
    /// <summary>
    /// Initialize the flags with the given mask.
    /// </summary>
    /// <param name="AMask">The mask to use.</param>
    constructor Create(const AMask: T); reintroduce;
  end;

  {/////////////////////////////////////////////////////////////////////////////
    ByteFlag  (8 bits)
  /////////////////////////////////////////////////////////////////////////////}

  /// <summary>
  /// Represents a flag using a byte for masking.
  /// </summary>
  IByteFlag = interface(IFlag<Byte>)
    ['{A6F0E6C9-9F42-4A3D-9F5B-2C8E1BE7A8D3}']
    /// <summary>Check if the 1st bit is set.</summary>
    function GetBit0: Boolean;
    /// <summary>Check if the 2nd bit is set.</summary>
    function GetBit1: Boolean;
    /// <summary>Check if the 3rd bit is set.</summary>
    function GetBit2: Boolean;
    /// <summary>Check if the 4th bit is set.</summary>
    function GetBit3: Boolean;
    /// <summary>Check if the 5th bit is set.</summary>
    function GetBit4: Boolean;
    /// <summary>Check if the 6th bit is set.</summary>
    function GetBit5: Boolean;
    /// <summary>Check if the 7th bit is set.</summary>
    function GetBit6: Boolean;
    /// <summary>Check if the 8th bit is set.</summary>
    function GetBit7: Boolean;

    /// <summary>Check if the 1st bit is set.</summary>
    property Bit0: Boolean read GetBit0;
    /// <summary>Check if the 2nd bit is set.</summary>
    property Bit1: Boolean read GetBit1;
    /// <summary>Check if the 3rd bit is set.</summary>
    property Bit2: Boolean read GetBit2;
    /// <summary>Check if the 4th bit is set.</summary>
    property Bit3: Boolean read GetBit3;
    /// <summary>Check if the 5th bit is set.</summary>
    property Bit4: Boolean read GetBit4;
    /// <summary>Check if the 6th bit is set.</summary>
    property Bit5: Boolean read GetBit5;
    /// <summary>Check if the 7th bit is set.</summary>
    property Bit6: Boolean read GetBit6;
    /// <summary>Check if the 8th bit is set.</summary>
    property Bit7: Boolean read GetBit7;
  end;

  /// <summary>
  /// Represents a flag using a byte for masking.
  /// </summary>
  TByteFlag = class sealed(TFlag<Byte>, IByteFlag)
  strict private
    // Bit accessors (1..8) mapped to Bit0..Bit7
    function GetBit0: Boolean;
    function GetBit1: Boolean;
    function GetBit2: Boolean;
    function GetBit3: Boolean;
    function GetBit4: Boolean;
    function GetBit5: Boolean;
    function GetBit6: Boolean;
    function GetBit7: Boolean;
  public
    /// <summary>
    /// Initialize the flags with the given byte.
    /// </summary>
    /// <param name="AMask">The byte to use.</param>
    constructor Create(const AMask: Byte);
  end;

  {/////////////////////////////////////////////////////////////////////////////
    ShortFlag (16 bits)
  /////////////////////////////////////////////////////////////////////////////}

  /// <summary>
  /// Represents a flag using a short for masking.
  /// </summary>
  IShortFlag = interface(IFlag<Word>)
    ['{8B6FC0C9-8A2D-4C75-879A-6B2B4D8E0E97}']
    function GetBit0: Boolean;
    function GetBit1: Boolean;
    function GetBit2: Boolean;
    function GetBit3: Boolean;
    function GetBit4: Boolean;
    function GetBit5: Boolean;
    function GetBit6: Boolean;
    function GetBit7: Boolean;
    function GetBit8: Boolean;
    function GetBit9: Boolean;
    function GetBit10: Boolean;
    function GetBit11: Boolean;
    function GetBit12: Boolean;
    function GetBit13: Boolean;
    function GetBit14: Boolean;
    function GetBit15: Boolean;

    property Bit0: Boolean read GetBit0;
    property Bit1: Boolean read GetBit1;
    property Bit2: Boolean read GetBit2;
    property Bit3: Boolean read GetBit3;
    property Bit4: Boolean read GetBit4;
    property Bit5: Boolean read GetBit5;
    property Bit6: Boolean read GetBit6;
    property Bit7: Boolean read GetBit7;
    property Bit8:  Boolean read GetBit8;
    property Bit9:  Boolean read GetBit9;
    property Bit10: Boolean read GetBit10;
    property Bit11: Boolean read GetBit11;
    property Bit12: Boolean read GetBit12;
    property Bit13: Boolean read GetBit13;
    property Bit14: Boolean read GetBit14;
    property Bit15: Boolean read GetBit15;
  end;

  /// <summary>
  /// Represents a flag using a short for masking.
  /// </summary>
  TShortFlag = class sealed(TFlag<Word>, IShortFlag)
  strict private
    function GetBit0: Boolean;
    function GetBit1: Boolean;
    function GetBit2: Boolean;
    function GetBit3: Boolean;
    function GetBit4: Boolean;
    function GetBit5: Boolean;
    function GetBit6: Boolean;
    function GetBit7: Boolean;
    function GetBit8: Boolean;
    function GetBit9: Boolean;
    function GetBit10: Boolean;
    function GetBit11: Boolean;
    function GetBit12: Boolean;
    function GetBit13: Boolean;
    function GetBit14: Boolean;
    function GetBit15: Boolean;
  public
    /// <summary>
    /// Initialize the flags with the given ushort.
    /// </summary>
    /// <param name="AMask">The ushort to use.</param>
    constructor Create(const AMask: Word);
  end;

  {/////////////////////////////////////////////////////////////////////////////
    IntFlag   (32 bits)
  /////////////////////////////////////////////////////////////////////////////}

  /// <summary>
  /// Represents a flag using a long for masking.
  /// </summary>
  IIntFlag = interface(IFlag<Cardinal>)
    ['{E1BC0B0C-2C82-49D3-9C2D-5B0F7F502B8E}']
    function GetBit0: Boolean;
    function GetBit1: Boolean;
    function GetBit2: Boolean;
    function GetBit3: Boolean;
    function GetBit4: Boolean;
    function GetBit5: Boolean;
    function GetBit6: Boolean;
    function GetBit7: Boolean;
    function GetBit8: Boolean;
    function GetBit9: Boolean;
    function GetBit10: Boolean;
    function GetBit11: Boolean;
    function GetBit12: Boolean;
    function GetBit13: Boolean;
    function GetBit14: Boolean;
    function GetBit15: Boolean;
    function GetBit16: Boolean;
    function GetBit17: Boolean;
    function GetBit18: Boolean;
    function GetBit19: Boolean;
    function GetBit20: Boolean;
    function GetBit21: Boolean;
    function GetBit22: Boolean;
    function GetBit23: Boolean;
    function GetBit24: Boolean;
    function GetBit25: Boolean;
    function GetBit26: Boolean;
    function GetBit27: Boolean;
    function GetBit28: Boolean;
    function GetBit29: Boolean;
    function GetBit30: Boolean;
    function GetBit31: Boolean;

    property Bit0: Boolean read GetBit0;
    property Bit1: Boolean read GetBit1;
    property Bit2: Boolean read GetBit2;
    property Bit3: Boolean read GetBit3;
    property Bit4: Boolean read GetBit4;
    property Bit5: Boolean read GetBit5;
    property Bit6: Boolean read GetBit6;
    property Bit7: Boolean read GetBit7;
    property Bit8: Boolean read GetBit8;
    property Bit9: Boolean read GetBit9;
    property Bit10: Boolean read GetBit10;
    property Bit11: Boolean read GetBit11;
    property Bit12: Boolean read GetBit12;
    property Bit13: Boolean read GetBit13;
    property Bit14: Boolean read GetBit14;
    property Bit15: Boolean read GetBit15;
    property Bit16: Boolean read GetBit16;
    property Bit17: Boolean read GetBit17;
    property Bit18: Boolean read GetBit18;
    property Bit19: Boolean read GetBit19;
    property Bit20: Boolean read GetBit20;
    property Bit21: Boolean read GetBit21;
    property Bit22: Boolean read GetBit22;
    property Bit23: Boolean read GetBit23;
    property Bit24: Boolean read GetBit24;
    property Bit25: Boolean read GetBit25;
    property Bit26: Boolean read GetBit26;
    property Bit27: Boolean read GetBit27;
    property Bit28: Boolean read GetBit28;
    property Bit29: Boolean read GetBit29;
    property Bit30: Boolean read GetBit30;
    property Bit31: Boolean read GetBit31;
  end;

  /// <summary>
  /// Represents a flag using a long for masking.
  /// </summary>
  TIntFlag = class sealed(TFlag<Cardinal>, IIntFlag)
  strict private
    function GetBit0: Boolean;
    function GetBit1: Boolean;
    function GetBit2: Boolean;
    function GetBit3: Boolean;
    function GetBit4: Boolean;
    function GetBit5: Boolean;
    function GetBit6: Boolean;
    function GetBit7: Boolean;
    function GetBit8: Boolean;
    function GetBit9: Boolean;
    function GetBit10: Boolean;
    function GetBit11: Boolean;
    function GetBit12: Boolean;
    function GetBit13: Boolean;
    function GetBit14: Boolean;
    function GetBit15: Boolean;
    function GetBit16: Boolean;
    function GetBit17: Boolean;
    function GetBit18: Boolean;
    function GetBit19: Boolean;
    function GetBit20: Boolean;
    function GetBit21: Boolean;
    function GetBit22: Boolean;
    function GetBit23: Boolean;
    function GetBit24: Boolean;
    function GetBit25: Boolean;
    function GetBit26: Boolean;
    function GetBit27: Boolean;
    function GetBit28: Boolean;
    function GetBit29: Boolean;
    function GetBit30: Boolean;
    function GetBit31: Boolean;
  public
    /// <summary>
    /// Initialize the flags with the given uint.
    /// </summary>
    /// <param name="AMask">The uint to use.</param>
    constructor Create(const AMask: Cardinal);
  end;

  {/////////////////////////////////////////////////////////////////////////////
    LongFlag  (64 bits)
  /////////////////////////////////////////////////////////////////////////////}

  /// <summary>
  /// Represents a flag using a long for masking.
  /// </summary>
  ILongFlag = interface(IFlag<UInt64>)
    ['{6D1A1B1E-6F35-4B2A-8C36-5F1C0E0B2B91}']
    function GetBit0: Boolean;
    function GetBit1: Boolean;
    function GetBit2: Boolean;
    function GetBit3: Boolean;
    function GetBit4: Boolean;
    function GetBit5: Boolean;
    function GetBit6: Boolean;
    function GetBit7: Boolean;
    function GetBit8: Boolean;
    function GetBit9: Boolean;
    function GetBit10: Boolean;
    function GetBit11: Boolean;
    function GetBit12: Boolean;
    function GetBit13: Boolean;
    function GetBit14: Boolean;
    function GetBit15: Boolean;
    function GetBit16: Boolean;
    function GetBit17: Boolean;
    function GetBit18: Boolean;
    function GetBit19: Boolean;
    function GetBit20: Boolean;
    function GetBit21: Boolean;
    function GetBit22: Boolean;
    function GetBit23: Boolean;
    function GetBit24: Boolean;
    function GetBit25: Boolean;
    function GetBit26: Boolean;
    function GetBit27: Boolean;
    function GetBit28: Boolean;
    function GetBit29: Boolean;
    function GetBit30: Boolean;
    function GetBit31: Boolean;
    function GetBit32: Boolean;
    function GetBit33: Boolean;
    function GetBit34: Boolean;
    function GetBit35: Boolean;
    function GetBit36: Boolean;
    function GetBit37: Boolean;
    function GetBit38: Boolean;
    function GetBit39: Boolean;
    function GetBit40: Boolean;
    function GetBit41: Boolean;
    function GetBit42: Boolean;
    function GetBit43: Boolean;
    function GetBit44: Boolean;
    function GetBit45: Boolean;
    function GetBit46: Boolean;
    function GetBit47: Boolean;
    function GetBit48: Boolean;
    function GetBit49: Boolean;
    function GetBit50: Boolean;
    function GetBit51: Boolean;
    function GetBit52: Boolean;
    function GetBit53: Boolean;
    function GetBit54: Boolean;
    function GetBit55: Boolean;
    function GetBit56: Boolean;
    function GetBit57: Boolean;
    function GetBit58: Boolean;
    function GetBit59: Boolean;
    function GetBit60: Boolean;
    function GetBit61: Boolean;
    function GetBit62: Boolean;
    function GetBit63: Boolean;

    property Bit0: Boolean read GetBit0;
    property Bit1: Boolean read GetBit1;
    property Bit2: Boolean read GetBit2;
    property Bit3: Boolean read GetBit3;
    property Bit4: Boolean read GetBit4;
    property Bit5: Boolean read GetBit5;
    property Bit6: Boolean read GetBit6;
    property Bit7: Boolean read GetBit7;
    property Bit8: Boolean read GetBit8;
    property Bit9: Boolean read GetBit9;
    property Bit10: Boolean read GetBit10;
    property Bit11: Boolean read GetBit11;
    property Bit12: Boolean read GetBit12;
    property Bit13: Boolean read GetBit13;
    property Bit14: Boolean read GetBit14;
    property Bit15: Boolean read GetBit15;
    property Bit16: Boolean read GetBit16;
    property Bit17: Boolean read GetBit17;
    property Bit18: Boolean read GetBit18;
    property Bit19: Boolean read GetBit19;
    property Bit20: Boolean read GetBit20;
    property Bit21: Boolean read GetBit21;
    property Bit22: Boolean read GetBit22;
    property Bit23: Boolean read GetBit23;
    property Bit24: Boolean read GetBit24;
    property Bit25: Boolean read GetBit25;
    property Bit26: Boolean read GetBit26;
    property Bit27: Boolean read GetBit27;
    property Bit28: Boolean read GetBit28;
    property Bit29: Boolean read GetBit29;
    property Bit30: Boolean read GetBit30;
    property Bit31: Boolean read GetBit31;
    property Bit32: Boolean read GetBit32;
    property Bit33: Boolean read GetBit33;
    property Bit34: Boolean read GetBit34;
    property Bit35: Boolean read GetBit35;
    property Bit36: Boolean read GetBit36;
    property Bit37: Boolean read GetBit37;
    property Bit38: Boolean read GetBit38;
    property Bit39: Boolean read GetBit39;
    property Bit40: Boolean read GetBit40;
    property Bit41: Boolean read GetBit41;
    property Bit42: Boolean read GetBit42;
    property Bit43: Boolean read GetBit43;
    property Bit44: Boolean read GetBit44;
    property Bit45: Boolean read GetBit45;
    property Bit46: Boolean read GetBit46;
    property Bit47: Boolean read GetBit47;
    property Bit48: Boolean read GetBit48;
    property Bit49: Boolean read GetBit49;
    property Bit50: Boolean read GetBit50;
    property Bit51: Boolean read GetBit51;
    property Bit52: Boolean read GetBit52;
    property Bit53: Boolean read GetBit53;
    property Bit54: Boolean read GetBit54;
    property Bit55: Boolean read GetBit55;
    property Bit56: Boolean read GetBit56;
    property Bit57: Boolean read GetBit57;
    property Bit58: Boolean read GetBit58;
    property Bit59: Boolean read GetBit59;
    property Bit60: Boolean read GetBit60;
    property Bit61: Boolean read GetBit61;
    property Bit62: Boolean read GetBit62;
    property Bit63: Boolean read GetBit63;
  end;

  /// <summary>
  /// Represents a flag using a long for masking.
  /// </summary>
  TLongFlag = class sealed(TFlag<UInt64>, ILongFlag)
  strict private
    function GetBit0: Boolean;
    function GetBit1: Boolean;
    function GetBit2: Boolean;
    function GetBit3: Boolean;
    function GetBit4: Boolean;
    function GetBit5: Boolean;
    function GetBit6: Boolean;
    function GetBit7: Boolean;
    function GetBit8: Boolean;
    function GetBit9: Boolean;
    function GetBit10: Boolean;
    function GetBit11: Boolean;
    function GetBit12: Boolean;
    function GetBit13: Boolean;
    function GetBit14: Boolean;
    function GetBit15: Boolean;
    function GetBit16: Boolean;
    function GetBit17: Boolean;
    function GetBit18: Boolean;
    function GetBit19: Boolean;
    function GetBit20: Boolean;
    function GetBit21: Boolean;
    function GetBit22: Boolean;
    function GetBit23: Boolean;
    function GetBit24: Boolean;
    function GetBit25: Boolean;
    function GetBit26: Boolean;
    function GetBit27: Boolean;
    function GetBit28: Boolean;
    function GetBit29: Boolean;
    function GetBit30: Boolean;
    function GetBit31: Boolean;
    function GetBit32: Boolean;
    function GetBit33: Boolean;
    function GetBit34: Boolean;
    function GetBit35: Boolean;
    function GetBit36: Boolean;
    function GetBit37: Boolean;
    function GetBit38: Boolean;
    function GetBit39: Boolean;
    function GetBit40: Boolean;
    function GetBit41: Boolean;
    function GetBit42: Boolean;
    function GetBit43: Boolean;
    function GetBit44: Boolean;
    function GetBit45: Boolean;
    function GetBit46: Boolean;
    function GetBit47: Boolean;
    function GetBit48: Boolean;
    function GetBit49: Boolean;
    function GetBit50: Boolean;
    function GetBit51: Boolean;
    function GetBit52: Boolean;
    function GetBit53: Boolean;
    function GetBit54: Boolean;
    function GetBit55: Boolean;
    function GetBit56: Boolean;
    function GetBit57: Boolean;
    function GetBit58: Boolean;
    function GetBit59: Boolean;
    function GetBit60: Boolean;
    function GetBit61: Boolean;
    function GetBit62: Boolean;
    function GetBit63: Boolean;
  public
    /// <summary>
    /// Initialize the flags with the given ulong.
    /// </summary>
    /// <param name="AMask">The ulong to use.</param>
    constructor Create(const AMask: UInt64);
  end;

implementation

{ TFlag<T> }

constructor TFlag<T>.Create(const AMask: T);
begin
  inherited Create;
  FValue := AMask;
end;

function TFlag<T>.GetValue: T;
begin
  Result := FValue;
end;

class function TFlag<T>.IsKthBitSet(const AN: UInt64; const AK: Integer): Boolean;
begin
  Result := (AN and (UInt64(1) shl (AK - 1))) > 0;
end;

{ TByteFlag }

constructor TByteFlag.Create(const AMask: Byte);
begin
  inherited Create(AMask);
end;

function TByteFlag.GetBit0: Boolean; begin Result := IsKthBitSet(Value, 1); end;
function TByteFlag.GetBit1: Boolean; begin Result := IsKthBitSet(Value, 2);  end;
function TByteFlag.GetBit2: Boolean; begin Result := IsKthBitSet(Value, 3);  end;
function TByteFlag.GetBit3: Boolean; begin Result := IsKthBitSet(Value, 4);  end;
function TByteFlag.GetBit4: Boolean; begin Result := IsKthBitSet(Value, 5);  end;
function TByteFlag.GetBit5: Boolean; begin Result := IsKthBitSet(Value, 6);  end;
function TByteFlag.GetBit6: Boolean; begin Result := IsKthBitSet(Value, 7);  end;
function TByteFlag.GetBit7: Boolean; begin Result := IsKthBitSet(Value, 8);  end;

{ TShortFlag }

constructor TShortFlag.Create(const AMask: Word);
begin
  inherited Create(AMask);
end;

function TShortFlag.GetBit0: Boolean; begin Result := IsKthBitSet(Value, 1);  end;
function TShortFlag.GetBit1: Boolean; begin Result := IsKthBitSet(Value, 2);  end;
function TShortFlag.GetBit2: Boolean; begin Result := IsKthBitSet(Value, 3);  end;
function TShortFlag.GetBit3: Boolean; begin Result := IsKthBitSet(Value, 4);  end;
function TShortFlag.GetBit4: Boolean; begin Result := IsKthBitSet(Value, 5);  end;
function TShortFlag.GetBit5: Boolean; begin Result := IsKthBitSet(Value, 6);  end;
function TShortFlag.GetBit6: Boolean; begin Result := IsKthBitSet(Value, 7);  end;
function TShortFlag.GetBit7: Boolean; begin Result := IsKthBitSet(Value, 8);  end;
function TShortFlag.GetBit8: Boolean; begin Result := IsKthBitSet(Value, 9);  end;
function TShortFlag.GetBit9: Boolean; begin Result := IsKthBitSet(Value, 10); end;
function TShortFlag.GetBit10: Boolean; begin Result := IsKthBitSet(Value, 11); end;
function TShortFlag.GetBit11: Boolean; begin Result := IsKthBitSet(Value, 12); end;
function TShortFlag.GetBit12: Boolean; begin Result := IsKthBitSet(Value, 13); end;
function TShortFlag.GetBit13: Boolean; begin Result := IsKthBitSet(Value, 14); end;
function TShortFlag.GetBit14: Boolean; begin Result := IsKthBitSet(Value, 15); end;
function TShortFlag.GetBit15: Boolean; begin Result := IsKthBitSet(Value, 16); end;

{ TIntFlag }

constructor TIntFlag.Create(const AMask: Cardinal);
begin
  inherited Create(AMask);
end;

function TIntFlag.GetBit0: Boolean; begin Result := IsKthBitSet(Value, 1);  end;
function TIntFlag.GetBit1: Boolean; begin Result := IsKthBitSet(Value, 2);  end;
function TIntFlag.GetBit2: Boolean; begin Result := IsKthBitSet(Value, 3);  end;
function TIntFlag.GetBit3: Boolean; begin Result := IsKthBitSet(Value, 4);  end;
function TIntFlag.GetBit4: Boolean; begin Result := IsKthBitSet(Value, 5);  end;
function TIntFlag.GetBit5: Boolean; begin Result := IsKthBitSet(Value, 6);  end;
function TIntFlag.GetBit6: Boolean; begin Result := IsKthBitSet(Value, 7);  end;
function TIntFlag.GetBit7: Boolean; begin Result := IsKthBitSet(Value, 8);  end;
function TIntFlag.GetBit8: Boolean; begin Result := IsKthBitSet(Value, 9);  end;
function TIntFlag.GetBit9: Boolean; begin Result := IsKthBitSet(Value, 10); end;
function TIntFlag.GetBit10: Boolean; begin Result := IsKthBitSet(Value, 11); end;
function TIntFlag.GetBit11: Boolean; begin Result := IsKthBitSet(Value, 12); end;
function TIntFlag.GetBit12: Boolean; begin Result := IsKthBitSet(Value, 13); end;
function TIntFlag.GetBit13: Boolean; begin Result := IsKthBitSet(Value, 14); end;
function TIntFlag.GetBit14: Boolean; begin Result := IsKthBitSet(Value, 15); end;
function TIntFlag.GetBit15: Boolean; begin Result := IsKthBitSet(Value, 16); end;
function TIntFlag.GetBit16: Boolean; begin Result := IsKthBitSet(Value, 17); end;
function TIntFlag.GetBit17: Boolean; begin Result := IsKthBitSet(Value, 18); end;
function TIntFlag.GetBit18: Boolean; begin Result := IsKthBitSet(Value, 19); end;
function TIntFlag.GetBit19: Boolean; begin Result := IsKthBitSet(Value, 20); end;
function TIntFlag.GetBit20: Boolean; begin Result := IsKthBitSet(Value, 21); end;
function TIntFlag.GetBit21: Boolean; begin Result := IsKthBitSet(Value, 22); end;
function TIntFlag.GetBit22: Boolean; begin Result := IsKthBitSet(Value, 23); end;
function TIntFlag.GetBit23: Boolean; begin Result := IsKthBitSet(Value, 24); end;
function TIntFlag.GetBit24: Boolean; begin Result := IsKthBitSet(Value, 25); end;
function TIntFlag.GetBit25: Boolean; begin Result := IsKthBitSet(Value, 26); end;
function TIntFlag.GetBit26: Boolean; begin Result := IsKthBitSet(Value, 27); end;
function TIntFlag.GetBit27: Boolean; begin Result := IsKthBitSet(Value, 28); end;
function TIntFlag.GetBit28: Boolean; begin Result := IsKthBitSet(Value, 29); end;
function TIntFlag.GetBit29: Boolean; begin Result := IsKthBitSet(Value, 30); end;
function TIntFlag.GetBit30: Boolean; begin Result := IsKthBitSet(Value, 31); end;
function TIntFlag.GetBit31: Boolean; begin Result := IsKthBitSet(Value, 32); end;

{ TLongFlag }

constructor TLongFlag.Create(const AMask: UInt64);
begin
  inherited Create(AMask);
end;

function TLongFlag.GetBit0: Boolean; begin Result := IsKthBitSet(Value, 1);  end;
function TLongFlag.GetBit1: Boolean; begin Result := IsKthBitSet(Value, 2);  end;
function TLongFlag.GetBit2: Boolean; begin Result := IsKthBitSet(Value, 3);  end;
function TLongFlag.GetBit3: Boolean; begin Result := IsKthBitSet(Value, 4);  end;
function TLongFlag.GetBit4: Boolean; begin Result := IsKthBitSet(Value, 5);  end;
function TLongFlag.GetBit5: Boolean; begin Result := IsKthBitSet(Value, 6);  end;
function TLongFlag.GetBit6: Boolean; begin Result := IsKthBitSet(Value, 7);  end;
function TLongFlag.GetBit7: Boolean; begin Result := IsKthBitSet(Value, 8);  end;
function TLongFlag.GetBit8: Boolean; begin Result := IsKthBitSet(Value, 9);  end;
function TLongFlag.GetBit9: Boolean; begin Result := IsKthBitSet(Value, 10); end;
function TLongFlag.GetBit10: Boolean; begin Result := IsKthBitSet(Value, 11); end;
function TLongFlag.GetBit11: Boolean; begin Result := IsKthBitSet(Value, 12); end;
function TLongFlag.GetBit12: Boolean; begin Result := IsKthBitSet(Value, 13); end;
function TLongFlag.GetBit13: Boolean; begin Result := IsKthBitSet(Value, 14); end;
function TLongFlag.GetBit14: Boolean; begin Result := IsKthBitSet(Value, 15); end;
function TLongFlag.GetBit15: Boolean; begin Result := IsKthBitSet(Value, 16); end;
function TLongFlag.GetBit16: Boolean; begin Result := IsKthBitSet(Value, 17); end;
function TLongFlag.GetBit17: Boolean; begin Result := IsKthBitSet(Value, 18); end;
function TLongFlag.GetBit18: Boolean; begin Result := IsKthBitSet(Value, 19); end;
function TLongFlag.GetBit19: Boolean; begin Result := IsKthBitSet(Value, 20); end;
function TLongFlag.GetBit20: Boolean; begin Result := IsKthBitSet(Value, 21); end;
function TLongFlag.GetBit21: Boolean; begin Result := IsKthBitSet(Value, 22); end;
function TLongFlag.GetBit22: Boolean; begin Result := IsKthBitSet(Value, 23); end;
function TLongFlag.GetBit23: Boolean; begin Result := IsKthBitSet(Value, 24); end;
function TLongFlag.GetBit24: Boolean; begin Result := IsKthBitSet(Value, 25); end;
function TLongFlag.GetBit25: Boolean; begin Result := IsKthBitSet(Value, 26); end;
function TLongFlag.GetBit26: Boolean; begin Result := IsKthBitSet(Value, 27); end;
function TLongFlag.GetBit27: Boolean; begin Result := IsKthBitSet(Value, 28); end;
function TLongFlag.GetBit28: Boolean; begin Result := IsKthBitSet(Value, 29); end;
function TLongFlag.GetBit29: Boolean; begin Result := IsKthBitSet(Value, 30); end;
function TLongFlag.GetBit30: Boolean; begin Result := IsKthBitSet(Value, 31); end;
function TLongFlag.GetBit31: Boolean; begin Result := IsKthBitSet(Value, 32); end;
function TLongFlag.GetBit32: Boolean; begin Result := IsKthBitSet(Value, 33); end;
function TLongFlag.GetBit33: Boolean; begin Result := IsKthBitSet(Value, 34); end;
function TLongFlag.GetBit34: Boolean; begin Result := IsKthBitSet(Value, 35); end;
function TLongFlag.GetBit35: Boolean; begin Result := IsKthBitSet(Value, 36); end;
function TLongFlag.GetBit36: Boolean; begin Result := IsKthBitSet(Value, 37); end;
function TLongFlag.GetBit37: Boolean; begin Result := IsKthBitSet(Value, 38); end;
function TLongFlag.GetBit38: Boolean; begin Result := IsKthBitSet(Value, 39); end;
function TLongFlag.GetBit39: Boolean; begin Result := IsKthBitSet(Value, 40); end;
function TLongFlag.GetBit40: Boolean; begin Result := IsKthBitSet(Value, 41); end;
function TLongFlag.GetBit41: Boolean; begin Result := IsKthBitSet(Value, 42); end;
function TLongFlag.GetBit42: Boolean; begin Result := IsKthBitSet(Value, 43); end;
function TLongFlag.GetBit43: Boolean; begin Result := IsKthBitSet(Value, 44); end;
function TLongFlag.GetBit44: Boolean; begin Result := IsKthBitSet(Value, 45); end;
function TLongFlag.GetBit45: Boolean; begin Result := IsKthBitSet(Value, 46); end;
function TLongFlag.GetBit46: Boolean; begin Result := IsKthBitSet(Value, 47); end;
function TLongFlag.GetBit47: Boolean; begin Result := IsKthBitSet(Value, 48); end;
function TLongFlag.GetBit48: Boolean; begin Result := IsKthBitSet(Value, 49); end;
function TLongFlag.GetBit49: Boolean; begin Result := IsKthBitSet(Value, 50); end;
function TLongFlag.GetBit50: Boolean; begin Result := IsKthBitSet(Value, 51); end;
function TLongFlag.GetBit51: Boolean; begin Result := IsKthBitSet(Value, 52); end;
function TLongFlag.GetBit52: Boolean; begin Result := IsKthBitSet(Value, 53); end;
function TLongFlag.GetBit53: Boolean; begin Result := IsKthBitSet(Value, 54); end;
function TLongFlag.GetBit54: Boolean; begin Result := IsKthBitSet(Value, 55); end;
function TLongFlag.GetBit55: Boolean; begin Result := IsKthBitSet(Value, 56); end;
function TLongFlag.GetBit56: Boolean; begin Result := IsKthBitSet(Value, 57); end;
function TLongFlag.GetBit57: Boolean; begin Result := IsKthBitSet(Value, 58); end;
function TLongFlag.GetBit58: Boolean; begin Result := IsKthBitSet(Value, 59); end;
function TLongFlag.GetBit59: Boolean; begin Result := IsKthBitSet(Value, 60); end;
function TLongFlag.GetBit60: Boolean; begin Result := IsKthBitSet(Value, 61); end;
function TLongFlag.GetBit61: Boolean; begin Result := IsKthBitSet(Value, 62); end;
function TLongFlag.GetBit62: Boolean; begin Result := IsKthBitSet(Value, 63); end;
function TLongFlag.GetBit63: Boolean; begin Result := IsKthBitSet(Value, 64); end;

end.

