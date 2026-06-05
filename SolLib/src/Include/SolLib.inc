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

{========================== Resource Loading Validation =======================}

// Ensure one resource loading strategy is defined
{$IF NOT DEFINED(USE_EMBEDDED_RESOURCES) AND NOT DEFINED(USE_FILE_RESOURCES)}
  {$MESSAGE ERROR 'Unsupported platform: Either USE_EMBEDDED_RESOURCES or USE_FILE_RESOURCES must be defined'}
{$IFEND}

{========================== Crypto Provider Strategy ===========================}

// To use custom crypto providers, define USE_CUSTOM_CRYPTO_PROVIDERS instead

//{$DEFINE USE_CUSTOM_CRYPTO_PROVIDERS}

{$IF NOT DEFINED(USE_CUSTOM_CRYPTO_PROVIDERS)}
  {$DEFINE USE_DEFAULT_CRYPTO_PROVIDERS}
{$IFEND}

{=========================== Crypto Provider Validation ========================}

// Ensure at least one crypto provider strategy is defined
{$IF NOT DEFINED(USE_DEFAULT_CRYPTO_PROVIDERS) AND NOT DEFINED(USE_CUSTOM_CRYPTO_PROVIDERS)}
  {$MESSAGE ERROR 'Either USE_DEFAULT_CRYPTO_PROVIDERS or USE_CUSTOM_CRYPTO_PROVIDERS must be defined'}
{$IFEND}

// Ensure not more than one crypto provider strategy is defined
{$IF DEFINED(USE_DEFAULT_CRYPTO_PROVIDERS) AND DEFINED(USE_CUSTOM_CRYPTO_PROVIDERS)}
  {$MESSAGE ERROR 'USE_DEFAULT_CRYPTO_PROVIDERS and USE_CUSTOM_CRYPTO_PROVIDERS cannot both be defined'}
{$IFEND}

{========================== Data Encoder Provider Strategy ===========================}

// To use custom encoder providers, define USE_CUSTOM_DATA_ENCODER_PROVIDERS instead

//{$DEFINE USE_CUSTOM_DATA_ENCODER_PROVIDERS}

{$IF NOT DEFINED(USE_CUSTOM_DATA_ENCODER_PROVIDERS)}
  {$DEFINE USE_DEFAULT_DATA_ENCODER_PROVIDERS}
{$IFEND}

{=========================== Data Encoder Provider Validation ========================}

// Ensure at least one data encoder provider strategy is defined
{$IF NOT DEFINED(USE_DEFAULT_DATA_ENCODER_PROVIDERS) AND NOT DEFINED(USE_CUSTOM_DATA_ENCODER_PROVIDERS)}
  {$MESSAGE ERROR 'Either USE_DEFAULT_DATA_ENCODER_PROVIDERS or USE_CUSTOM_DATA_ENCODER_PROVIDERS must be defined'}
{$IFEND}

// Ensure not more than one data encoder provider strategy is defined
{$IF DEFINED(USE_DEFAULT_DATA_ENCODER_PROVIDERS) AND DEFINED(USE_CUSTOM_DATA_ENCODER_PROVIDERS)}
   {$MESSAGE ERROR 'USE_DEFAULT_DATA_ENCODER_PROVIDERS and USE_CUSTOM_DATA_ENCODER_PROVIDERS cannot both be defined'}
{$IFEND}

(* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& *)
