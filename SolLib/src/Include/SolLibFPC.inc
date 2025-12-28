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

{$IFDEF FPC}
  {$MESSAGE FATAL 'This Library does not support Free Pascal Compiler (FPC). Please use Delphi instead.'}

  {$IFDEF ENDIAN_BIG}
    {$MESSAGE FATAL 'This Library does not support "Big Endian" processors yet.'}
  {$ENDIF}

  {$MODE DELPHI}
  {$MACRO ON}
  {$NOTES OFF}
  {$OPTIMIZATION LEVEL3}
  {$OPTIMIZATION NOUSELOADMODIFYSTORE}
  {$OPTIMIZATION ORDERFIELDS}
  {$OPTIMIZATION DEADVALUES}
  {$IFDEF CPUI386}  {$OPTIMIZATION USEEBP} {$ENDIF}
  {$IFDEF CPUX86_64} {$OPTIMIZATION USERBP} {$ENDIF}

{========================== Resource Loading Strategy =========================}

  // FPC supports embedded resources via TResourceStream
  {$DEFINE USE_EMBEDDED_RESOURCES}

{$ENDIF}

