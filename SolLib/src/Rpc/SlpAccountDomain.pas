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

unit SlpAccountDomain;

{$I ../Include/SolLib.inc}

interface

uses
  System.SysUtils,
  System.Math,
  System.Generics.Collections,
  System.Generics.Defaults,
  SlpPublicKey;

type
  IAccountMeta = interface
    ['{A7F57C9C-6C5A-4E08-9A4E-3B2A6E7E5B3C}']
    function GetPublicKey: IPublicKey;
    function GetIsSigner: Boolean;
    procedure SetIsSigner(AValue: Boolean);
    function GetIsWritable: Boolean;
    procedure SetIsWritable(AValue: Boolean);

    function Clone: IAccountMeta;

    property PublicKey: IPublicKey read GetPublicKey;
    property IsSigner: Boolean read GetIsSigner write SetIsSigner;
    property IsWritable: Boolean read GetIsWritable write SetIsWritable;
  end;

  /// <summary>
  /// Implements the account meta logic, which defines if an account represented by public key is a signer, a writable account or both.
  /// </summary>
  TAccountMeta = class(TInterfacedObject, IAccountMeta)
  private
    FPublicKey: IPublicKey;
    FIsSigner: Boolean;
    FIsWritable: Boolean;

    function GetPublicKey: IPublicKey;
    function GetIsSigner: Boolean;
    procedure SetIsSigner(AValue: Boolean);
    function GetIsWritable: Boolean;
    procedure SetIsWritable(AValue: Boolean);

  public
    constructor Create(const APublicKey: IPublicKey; const AIsWritable, AIsSigner: Boolean);

    function Clone: IAccountMeta;

    /// <summary>
    /// Initializes an AccountMeta for a writable account with the given PublicKey
    /// and a bool that signals whether the account is a signer or not.
    /// </summary>
    class function Writable(const APublicKey: IPublicKey; const AIsSigner: Boolean): IAccountMeta; static;
    /// <summary>
    /// Initializes an AccountMeta for a read-only account with the given PublicKey
    /// and a bool that signals whether the account is a signer or not.
    /// </summary>
    class function ReadOnly(const APublicKey: IPublicKey; const AIsSigner: Boolean): IAccountMeta; static;
  end;

type
  /// <summary>
  /// A wrapper around a list of <see cref="AccountMeta"/>s that takes care of deduplication
  /// and ordering according to the wire format specification.
  /// </summary>
  TAccountKeysList = class
  private
    FAccounts: TList<IAccountMeta>;
    function GetCount: Integer;
    function GetAccountList: TList<IAccountMeta>;
    function FindByPublicKey(const AKey: IPublicKey): IAccountMeta;
  public
    /// <summary>
    /// Initialize the account keys list for use within transaction building.
    /// </summary>
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Get the accounts as a list.
    /// Returns a NEW sorted list instance.
    /// </summary>
    property AccountList: TList<IAccountMeta> read GetAccountList;

    property Count: Integer read GetCount;

    /// <summary>
    /// Add an account meta to the list of accounts.
    /// </summary>
    /// <param name="AAccountMeta">The account meta to add.</param>
    procedure Add(AAccountMeta: IAccountMeta); overload;

    /// <summary>
    /// Add a list of account metas to the list of accounts.
    /// </summary>
    /// <param name="AAccountMetas">The account metas to add.</param>
    procedure Add(const AAccountMetas: array of IAccountMeta); overload;

    /// <summary>
    /// Add a list of account metas to the list of accounts.
    /// </summary>
    /// <param name="AAccountMetas">The account metas to add.</param>
    procedure Add(const AAccountMetas: TList<IAccountMeta>); overload;
  end;

implementation

{ TAccountMeta }

constructor TAccountMeta.Create(const APublicKey: IPublicKey; const AIsWritable, AIsSigner: Boolean);
begin
  inherited Create;
  if not Assigned(APublicKey) then
    raise EArgumentNilException.Create('PublicKey');
  FPublicKey := APublicKey;
  FIsWritable := AIsWritable;
  FIsSigner := AIsSigner;
end;

function TAccountMeta.GetPublicKey: IPublicKey;
begin
  Result := FPublicKey;
end;

function TAccountMeta.GetIsSigner: Boolean;
begin
  Result := FIsSigner;
end;

procedure TAccountMeta.SetIsSigner(AValue: Boolean);
begin
  FIsSigner := AValue;
end;

function TAccountMeta.GetIsWritable: Boolean;
begin
  Result := FIsWritable;
end;

procedure TAccountMeta.SetIsWritable(AValue: Boolean);
begin
  FIsWritable := AValue;
end;

function TAccountMeta.Clone: IAccountMeta;
begin
  Result := TAccountMeta.Create(FPublicKey.Clone, FIsWritable, FIsSigner);
end;

class function TAccountMeta.Writable(const APublicKey: IPublicKey; const AIsSigner: Boolean): IAccountMeta;
begin
  Result := TAccountMeta.Create(APublicKey, True, AIsSigner);
end;

class function TAccountMeta.ReadOnly(const APublicKey: IPublicKey; const AIsSigner: Boolean): IAccountMeta;
begin
  Result := TAccountMeta.Create(APublicKey, False, AIsSigner);
end;

{ TAccountKeysList }

constructor TAccountKeysList.Create;
begin
  inherited Create;
  FAccounts := TList<IAccountMeta>.Create();
end;

destructor TAccountKeysList.Destroy;
begin
  if Assigned(FAccounts) then
    FAccounts.Free;
  inherited Destroy;
end;

function TAccountKeysList.FindByPublicKey(const AKey: IPublicKey): IAccountMeta;
var
  LI: Integer;
  LItem: IAccountMeta;
begin
  Result := nil;
  for LI := 0 to FAccounts.Count - 1 do
  begin
    LItem := FAccounts[LI];
    if (LItem.PublicKey.Equals(AKey)) then
    begin
      Exit(LItem);
    end;
  end;
end;

function TAccountKeysList.GetCount: Integer;
begin
  Result := FAccounts.Count;
end;

function TAccountKeysList.GetAccountList: TList<IAccountMeta>;
type
  TMetaIdx = record
    Item: IAccountMeta;
    Index: Integer;
  end;
var
  LI: Integer;
  LPair: TMetaIdx;
  LPairs: TList<TMetaIdx>;
begin
  LPairs := TList<TMetaIdx>.Create;
  try
    LPairs.Capacity := FAccounts.Count;
    for LI := 0 to FAccounts.Count - 1 do
    begin
      LPair := Default(TMetaIdx);
      LPair.Item := FAccounts[LI];
      LPair.Index := LI;
      LPairs.Add(LPair);
    end;

    LPairs.Sort(
      TComparer<TMetaIdx>.Construct(
        function (const ALeft, ARight: TMetaIdx): Integer
        begin
          if ALeft.Item.IsSigner <> ARight.Item.IsSigner then
            Exit(IfThen(ALeft.Item.IsSigner, -1, 1));

          if ALeft.Item.IsWritable <> ARight.Item.IsWritable then
            Exit(IfThen(ALeft.Item.IsWritable, -1, 1));

          Result := Sign(CompareText(ALeft.Item.PublicKey.Key, ARight.Item.PublicKey.Key));
          if Result <> 0 then
            Exit(Result);

          // Stable tiebreaker: preserve insertion order
          //Result := Sign(ALeft.Index - ARight.Index);
          Result := TComparer<Integer>.Default.Compare(ALeft.Index, ARight.Index);
        end
      )
    );

    Result := TList<IAccountMeta>.Create;
    try
      Result.Capacity := LPairs.Count;
      for LI := 0 to LPairs.Count - 1 do
        Result.Add(LPairs[LI].Item);
    except
      Result.Free;
      raise;
    end;
  finally
    LPairs.Free;
  end;
end;

procedure TAccountKeysList.Add(AAccountMeta: IAccountMeta);
var
  LExisting: IAccountMeta;
begin
  if AAccountMeta = nil then
    Exit;

  LExisting := FindByPublicKey(AAccountMeta.PublicKey);

  if LExisting = nil then
  begin
    FAccounts.Add(AAccountMeta)
  end
  else
  begin
    // Merge flags:
    // if existing is not signer but new is signer -> promote
    if (not LExisting.IsSigner) and AAccountMeta.IsSigner then
      LExisting.IsSigner := True;

    // if existing is not writable but new is writable -> promote
    if (not LExisting.IsWritable) and AAccountMeta.IsWritable then
      LExisting.IsWritable := True;
  end;
end;

procedure TAccountKeysList.Add(const AAccountMetas: array of IAccountMeta);
var
  LI: Integer;
begin
  for LI := 0 to High(AAccountMetas) do
    Add(AAccountMetas[LI]);
end;

procedure TAccountKeysList.Add(const AAccountMetas: TList<IAccountMeta>);
var
  LI: Integer;
begin
  for LI := 0 to AAccountMetas.Count - 1 do
    Add(AAccountMetas[LI]);
end;

end.

