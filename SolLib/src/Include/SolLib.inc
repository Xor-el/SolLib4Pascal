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

{========================= Compiler Specific Settings =========================}
{$IFDEF FPC}
  {$I SolLibFPC.inc}
{$ELSE}
   // Delphi 10.4 Sydney and Above
  {$IF CompilerVersion < 34.0}
    {$MESSAGE ERROR 'This Library requires Delphi 10.4 Sydney or higher.'}
  {$IFEND}

  {$DEFINE DELPHI}

  {$DEFINITIONINFO ON} // Enable code browsing (Ctrl+Click)
  {$STRINGCHECKS OFF}
  {$WARN DUPLICATE_CTOR_DTOR OFF}

{========================== Resource Loading Strategy =========================}

  // Platforms that support embedded .res resources (TResourceStream)
  {$IF DEFINED(MSWINDOWS) OR DEFINED(MACOS) OR DEFINED(LINUX)}
    {$DEFINE USE_EMBEDDED_RESOURCES}
  {$IFEND}

  // Platforms that require file-based asset loading
  {$IF DEFINED(ANDROID) OR DEFINED(IOS)}
    {$DEFINE USE_FILE_RESOURCES}
  {$IFEND}

{$ENDIF}

{========================== Common Compiler Settings ==========================}

{$HINTS OFF}
{$WARNINGS OFF}
{$RANGECHECKS OFF}
{$OVERFLOWCHECKS OFF}
{$SCOPEDENUMS ON}
{$POINTERMATH ON}

(* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& *)

