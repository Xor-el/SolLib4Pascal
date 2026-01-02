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

unit SlpSolLibTypes;

{$I ../Include/SolLib.inc}

interface

{$IFDEF FPC}
type
  TProc = reference to procedure;
  TProc<T> = reference to procedure(Arg1: T);
  TProc<T1, T2> = reference to procedure(Arg1: T1; Arg2: T2);
  TProc<T1, T2, T3> = reference to procedure(Arg1: T1; Arg2: T2; Arg3: T3);
  TProc<T1, T2, T3, T4> = reference to procedure(Arg1: T1; Arg2: T2; Arg3: T3; Arg4: T4);

  TFunc<TResult> = reference to function: TResult;
  TFunc<T, TResult> = reference to function(Arg1: T): TResult;
  TFunc<T1, T2, TResult> = reference to function(Arg1: T1; Arg2: T2): TResult;
  TFunc<T1, T2, T3, TResult> = reference to function(Arg1: T1; Arg2: T2; Arg3: T3): TResult;
  TFunc<T1, T2, T3, T4, TResult> = reference to function(Arg1: T1; Arg2: T2; Arg3: T3; Arg4: T4): TResult;

  TPredicate<T> = reference to function(Arg1: T): Boolean;
{$ENDIF}

implementation

end.
