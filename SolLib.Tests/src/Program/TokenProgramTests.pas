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

unit TokenProgramTests;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
{$IFDEF FPC}
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF}
  SlpDataEncoders,
  SlpWallet,
  SlpAccount,
  SlpPublicKey,
  SlpRpcModel,
  SlpMessageDomain,
  SlpDecodedInstruction,
  SlpTransactionInstruction,
  SlpTokenProgram,
  SlpTokenProgramModel,
  SlpInstructionDecoder,
  TestUtils,
  SolLibProgramTestCase;

type
  TTokenProgramTests = class(TSolLibProgramTestCase)
  private

    const MnemonicWords =
      'route clerk disease box emerge airport loud waste attitude film army tray ' +
      'forward deal onion eight catalog surface unit card window walnut wealth medal';

    const InitializeMultisigMessage =
      'AwAJDEdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyeLALNX+Hq5QvYpjBUrxcE6c1OPFtuOsWTs' +
      'RwZ22JTNv0sF4mdbv4FGc/JcD4qM+DJXE0k+DhmNmPu8MItrFyfgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
      'AAAAAAAAAAAABqfVFxksXFEhjMlMPUrxf1ja7gibof1E49vZigAAAAC9PD4jUE81HRWVKjhuaeGhBDrUiRU' +
      'sQ8PRa6Gkh7BcAzbV0glem2ocQYDPKtsvb2P6eY+diK2RlCQbryCDiW9ENqhqvd4wlbvt2WLwsRs1GuOPhm' +
      'Rt728O9WHpObgVQ60+Im+a09G04MQPhepwoQn2VGuSmOoDsZvfRJ8im8hThYp3QXZN2eL1ihOJMfLOtOE0d' +
      'btnaKq58W0jnl+pjmXBBt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKkFSlNQ+F3IgtYUpVZyeIop' +
      'bd8eq6vQpgZ4iEky9O72oNRsOMzYJJil8tqxLyZCv3xaGw9O1hPoqUsFwShXE+aABQMCAAE0AAAAAJBLMwA' +
      'AAAAAYwEAAAAAAAAG3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqQoHAQQFBgcICQICAwMCAAI0AA' +
      'AAAGBNFgAAAAAAUgAAAAAAAAAG3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqQoCAgRDAAp4sAs1f' +
      '4erlC9imMFSvFwTpzU48W246xZOxHBnbYlM2wBT7yGUtArURga4Avg+yhMwOEM69UaXYBPa+5CFN2YhDQsB' +
      'ABJIZWxsbyBmcm9tIFNvbC5OZXQ=';

    const MintToMultisigMessage =
      'BQMFC0dpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyDpwtYu322rjxMK+ED8DutHhxOkdgN0Rl6/B7o' +
      'VsMMG69PD4jUE81HRWVKjhuaeGhBDrUiRUsQ8PRa6Gkh7BcAzbV0glem2ocQYDPKtsvb2P6eY+diK2RlCQbry' +
      'CDiW9EPiJvmtPRtODED4XqcKEJ9lRrkpjqA7Gb30SfIpvIU4X0sF4mdbv4FGc/JcD4qM+DJXE0k+DhmNmPu8' +
      'MItrFyfgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABqfVFxksXFEhjMlMPUrxf1ja7gibof1E49' +
      'vZigAAAAAG3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqXiwCzV/h6uUL2KYwVK8XBOnNTjxbbjrFk' +
      '7EcGdtiUzbBUpTUPhdyILWFKVWcniKKW3fHqur0KYGeIhJMvTu9qD2GZ+Dnx/yuoM4nlAAN0csYxYXMvDV/e' +
      'u6teeG3c6leQQGAgABNAAAAADwHR8AAAAAAKUAAAAAAAAABt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX' +
      '7/AKkIBAEFAAcBAQgGBQEJAgMECQeoYQAAAAAAAAoBABJIZWxsbyBmcm9tIFNvbC5OZXQ=';

    const MintToCheckedMultisigMessage =
      'BAMDCUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyvTw+I1BPNR0VlSo4bmnhoQQ61IkVLEPD0WuhpIewXAM21' +
      'dIJXptqHEGAzyrbL29j+nmPnYitkZQkG68gg4lvRD4ib5rT0bTgxA+F6nChCfZUa5KY6gOxm99EnyKbyFOF9LBeJnW7+BR' +
      'nPyXA+KjPgyVxNJPg4ZjZj7vDCLaxcn4OnC1i7fbauPEwr4QPwO60eHE6R2A3RGXr8HuhWwwwbniwCzV/h6uUL2KYwVK8' +
      'XBOnNTjxbbjrFk7EcGdtiUzbBt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKkFSlNQ+F3IgtYUpVZyeIopbd8eq' +
      '6vQpgZ4iEky9O72oNUxQB2XR+CQ9oj6l2DuNeQzPY0Dssm7niyiU8X1dvS0AgcGBAUGAQIDCg6oYQAAAAAAAAoIAQASS' +
      'GVsbG8gZnJvbSBTb2wuTmV0';

     const TransferCheckedMultisigMessage =
       'BAMDCUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyD2fbBe7VA8Jg3kfhUQh7HJ6f+hBs2QriyfCGiO1vi' +
       'oqKRK/h3D+lChZA2mVDAGmJHlYiSn8C/yKAGnfXHxgoMvF9c15So4YdnqahN6SHKY5ln1tsHqBpfwwM9RDfRR8GA/' +
       'GByjZ4HWOhY8ZF4ebvMWq3S6h+LX7eLV5BsR18QkUOnC1i7fbauPEwr4QPwO60eHE6R2A3RGXr8HuhWwwwbvSw' +
       'XiZ1u/gUZz8lwPioz4MlcTST4OGY2Y+7wwi2sXJ+6L8pyWJ/BaKAiW8dXpPWFLIy2KbXOugNumqQxVpmiB8G3fbh' +
       '12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqaMCTClqEJuWmr4VslMhwbyIcFZNPtJGGkoxxmHtSOumAQgHBAYF' +
       'BwECAwoMECcAAAAAAAAK';

     const BurnCheckedMessage =
       'AQACBUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyDpwtYu322rjxMK+ED8DutHhxOkdgN0Rl6/B7oVsM' +
       'MG70sF4mdbv4FGc/JcD4qM+DJXE0k+DhmNmPu8MItrFyfgbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCp' +
       'BUpTUPhdyILWFKVWcniKKW3fHqur0KYGeIhJMvTu9qB9EN8DB9phoLwJ2vF3TY8SIjNHH/yA9MfPfvoN5zUesAID' +
       'AwECAAoPqGEAAAAAAAAKBAEAEkhlbGxvIGZyb20gU29sLk5ldA==';

     const FreezeAccountMessage =
       'BAMECUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyCvMdxMgG61jhWyn8Fv1ZdwWpUYUJtZIrPCnzv7HW' +
       'fPFTn3mU+LXzjYbXul5/F+k78LFQWQ49hUbwa93RnuSO9GwRoB7PiR430F1c8KIlK9/8p1dvd4bCiUR1JwTbJ5Yy' +
       'P1HIPSemQoFZRkRRtdthf2YQ2HnhQ81DcQftvaA98N21sOi1KvUsX8inslpO8wtEufbBEGIGbN+5YDi5bVWz6nZ/b' +
       'VS3jG60hShrucjgp2V6fcq/E/6fO6aZK5BtOnjBBt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKkFSlNQ+F' +
       '3IgtYUpVZyeIopbd8eq6vQpgZ4iEky9O72oBugmJ2LefegA3b6kJPafbq49tUFNOTU5py6T7KOSfF6AgcGBAUGAQI' +
       'DAQoIAQASSGVsbG8gZnJvbSBTb2wuTmV0';

     const ThawAccountSetAuthorityMessage =
       'BAMDCUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyCvMdxMgG61jhWyn8Fv1ZdwWpUYUJtZIrPCnzv7HW' +
       'fPFTn3mU+LXzjYbXul5/F+k78LFQWQ49hUbwa93RnuSO9GwRoB7PiR430F1c8KIlK9/8p1dvd4bCiUR1JwTbJ5YyP' +
       '1HIPSemQoFZRkRRtdthf2YQ2HnhQ81DcQftvaA98N21sOi1KvUsX8inslpO8wtEufbBEGIGbN+5YDi5bVWz6nZ/bV' +
       'S3jG60hShrucjgp2V6fcq/E/6fO6aZK5BtOnjBBt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKkFSlNQ+F3' +
       'IgtYUpVZyeIopbd8eq6vQpgZ4iEky9O72oF2vvz8uXB7lyB6tJcZj0FSXajkBMaJFtoOucDxiBt2iAwcGBAUGAQID' +
       'AQsHBQUGAQIDIwYCAftRrCs+mafLAQLT3VW772fI0714b6QH4jibZkjI1x/kCAEAEkhlbGxvIGZyb20gU29sLk5ldA==';

     const ApproveCheckedMessage =
       'BAMFCkdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyhTqOe6WFo5EdWqrNj+11SlkAf/avKcg7AmcS0V1ne1' +
       '50g2o+tFASu728oBWKNjuukzpkMKVbzTVKaY2zOgu8Jbe8MvTWPYLci33hA669YhOTNoYC8GtC7eImCr6c9UnHqh6q' +
       'DWcsER1tQGsj3Y1l8TXqJaoqGvc/lEsGROMo3//wMHwddqmoX0GMOmMiZUpRelZsxO1FdBDNr5QhmEtkGMBs2t64Nb' +
       'n2DhZX+UaG9wt9VT3zkdKONg+Ipqmec3g0IcUCY4xOllbWIWHUtjIqMdsgVFRidruNg7yWWPNg43UG3fbh12Whk9nL' +
       '4UbO63msHLSF7V9bN5E6jPWFfv8AqQVKU1D4XciC1hSlVnJ4iilt3x6rq9CmBniISTL07vagdvGLii/m94eoZTnexZ' +
       'xgzw+z6PXaNMoJVckgwRwq588CCAcEBQYHAQIDCg2IEwAAAAAAAAoJAQASSGVsbG8gZnJvbSBTb2wuTmV0';

      const ApproveMessage =
        'BAMECUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyIm1L1m3jrd9QYA3DzPHQN1kFLGIJ6vGQA7Ypz1BSv' +
        'i1HtmdFn7ZE8VQa3Cq3XJ1mIUsz4hwJbe7ToemyTsJ9/Jrv9SFWJYlmgS6ev4iDPL7XQ9zIBWmWICKphL+HdgeFTd' +
        '/AW6lmc7MUabf26nqRFd3A6ZpD3XbLyeKVW+pG+MTAbNreuDW59g4WV/lGhvcLfVU985HSjjYPiKapnnN4NP4/SZb' +
        '2oWrgq2s47bqIUQTzMC94kc+nI7GSNjbPW4RaBt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKkFSlNQ+F3Ig' +
        'tYUpVZyeIopbd8eq6vQpgZ4iEky9O72oDX06JAMwhe5WoYBGQQmqvqWtrxSzxGc0GxYd2p+X0hWAgcGBAUGAQIDCQ' +
        'SIEwAAAAAAAAgBABJIZWxsbyBmcm9tIFNvbC5OZXQ=';

      const RevokeMessage =
        'BQQEC0dpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeywGza3rg1ufYOFlf5Rob3C31VPfOR0o42D4imqZ5z' +
        'eDRYzx0bbqHXZYNhsR3uwPVrTFAMTC0jx72rqhWoIoHmwGnqRA2sKfyYFmprjXtkN3o2rHVwgV4N0RtBqXQmEgro' +
        'Q0bNKgKurzONaQuvuPp40Nj2SwXQm0IkEhFFSRDOwP5RS26fJbuNJr8BprzZZY8EjBVEr0WiG/B7w95r2HrDdGR1' +
        'G8+hzi+pnKdf/z/2NDyrNxlFuCD1zxfJHsIrHKqT8DB8HXapqF9BjDpjImVKUXpWbMTtRXQQza+UIZhLZBgG3fbh' +
        '12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqV4Er7PSNNJpXv/iFEjgEy3WsK0DUo2VDAjvOSz/g9hpBUpTUPhd' +
        'yILWFKVWcniKKW3fHqur0KYGeIhJMvTu9qB+xPGUTXg2vBJsCn9SndzdNl7ce3CFxZEa4Z79/Jic2AMIBAUHBgEK' +
        'DIgTAAAAAAAACggFBQkCAwQBBQoBABJIZWxsbyBmcm9tIFNvbC5OZXQ=';

      const TransferMultisigMessage =
        'BAMCCEdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyD2fbBe7VA8Jg3kfhUQh7HJ6f+hBs2QriyfCGiO1vi' +
        'oqKRK/h3D+lChZA2mVDAGmJHlYiSn8C/yKAGnfXHxgoMvF9c15So4YdnqahN6SHKY5ln1tsHqBpfwwM9RDfRR8GO' +
        'YMO0iFs4aMUVosQrrL+aWspebSXbUiMaf5/Vser1b0OnC1i7fbauPEwr4QPwO60eHE6R2A3RGXr8HuhWwwwbpw3w' +
        'cgNZ/QXTgN9a+S2N3xz3NSvOB6j7IqBlRgLjbjHBt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKmB7X+UY' +
        '8KXED5lGuKAmWA0mMQr08QlXyeYC47yCxiX+QEHBgQFBgECAwkDECcAAAAAAAA=';

      const BurnMessage =
        'AQACBUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxey6Nz9cBhJOumlXLZpUvE8AzAtBfGMn1dZQnsmstBx' +
        'blH+AAGoyvg7ewB86TckKTC3zA8W969k9VFG1UHnZXHxLwbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCp' +
        'BUpTUPhdyILWFKVWcniKKW3fHqur0KYGeIhJMvTu9qDa9T+ewsQYcaXS8Ka3UtiOeLRbP1wKsuGLfGAyIfGM5QID' +
        'AwECAAkIyAAAAAAAAAAEAQASSGVsbG8gZnJvbSBTb2wuTmV0';

      const BurnMultisigMessage =
        'BwYEDUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeycDwgqOcK+3X1trbsFnKJjJKBgrQXdLlTOB5aifN' +
        'HLtKETKhqe0g+wN+JrGfVqRiZwqCoRuq712fzPKETjfAjo37NtrVZKnuugavqUxUkmxtuQXmdFg6sfds4GokwOq' +
        'CnWM8dG26h12WDYbEd7sD1a0xQDEwtI8e9q6oVqCKB5sBp6kQNrCn8mBZqa417ZDd6Nqx1cIFeDdEbQal0JhIK6' +
        'ENGzSoCrq8zjWkLr7j6eNDY9ksF0JtCJBIRRUkQzsD+8DB8HXapqF9BjDpjImVKUXpWbMTtRXQQza+UIZhLZBhR' +
        'S26fJbuNJr8BprzZZY8EjBVEr0WiG/B7w95r2HrDdL36Lc6g35sKjF+do2iqzBqjYUJKXlAnhXDJHsClu85XBt3' +
        '24ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKleBK+z0jTSaV7/4hRI4BMt1rCtA1KNlQwI7zks/4PYaQVKU1' +
        'D4XciC1hSlVnJ4iilt3x6rq9CmBniISTL07vagihio101USobGeALw3d3LcSK6mlzMa9mMnFhtC8Lu0TMDCgYHC' +
        'AkBAgMJBwDKmjsAAAAACgYIBwsEBQYJCCChBwAAAAAADAEAEkhlbGxvIGZyb20gU29sLk5ldA==';

      const BurnCheckedMultisigMessage =
        'BwYEDUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeycDwgqOcK+3X1trbsFnKJjJKBgrQXdLlTOB5aifN' +
        'HLtKETKhqe0g+wN+JrGfVqRiZwqCoRuq712fzPKETjfAjo37NtrVZKnuugavqUxUkmxtuQXmdFg6sfds4GokwOq' +
        'CnWM8dG26h12WDYbEd7sD1a0xQDEwtI8e9q6oVqCKB5sBp6kQNrCn8mBZqa417ZDd6Nqx1cIFeDdEbQal0JhIK' +
        '6ENGzSoCrq8zjWkLr7j6eNDY9ksF0JtCJBIRRUkQzsD+8DB8HXapqF9BjDpjImVKUXpWbMTtRXQQza+UIZhLZB' +
        'hRS26fJbuNJr8BprzZZY8EjBVEr0WiG/B7w95r2HrDdL36Lc6g35sKjF+do2iqzBqjYUJKXlAnhXDJHsClu85X' +
        'Bt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKleBK+z0jTSaV7/4hRI4BMt1rCtA1KNlQwI7zks/4PYa' +
        'QVKU1D4XciC1hSlVnJ4iilt3x6rq9CmBniISTL07vagcmeXtlaFxMMq4wKOUQQR6lX1/se+NU32JkeqamHOKW' +
        'YDCgYHCAkBAgMKDgDKmjsAAAAACgoGCAcLBAUGCg8goQcAAAAAAAoMAQASSGVsbG8gZnJvbSBTb2wuTmV0';

      const CloseAccountMultisigMessage =
        'BAMDCUdpq5cgS6g/sMruF/eGjx4HTlIVgaDYnZQ3napltxeyWM8dG26h12WDYbEd7sD1a0xQDEwtI8e9q6oVqC' +
        'KB5sBp6kQNrCn8mBZqa417ZDd6Nqx1cIFeDdEbQal0JhIK6ENGzSoCrq8zjWkLr7j6eNDY9ksF0JtCJBIRRUkQ' +
        'zsD+UUtunyW7jSa/Aaa82WWPBIwVRK9Fohvwe8Pea9h6w3TwMHwddqmoX0GMOmMiZUpRelZsxO1FdBDNr5QhmE' +
        'tkGF4Er7PSNNJpXv/iFEjgEy3WsK0DUo2VDAjvOSz/g9hpBt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/' +
        'AKkFSlNQ+F3IgtYUpVZyeIopbd8eq6vQpgZ4iEky9O72oBsCrLfKwExmcW/hntBXRIKAe6vTrQDRoyz2ZvGtaL' +
        '7sAwcGBAUGAQIDCg/gnyZ3AAAAAAoHBgQABgECAwEJCAEAEkhlbGxvIGZyb20gU29sLk5ldA==';

      const MultiSignatureAccountBase64Data =
        'AwUBWM8dG26h12WDYbEd7sD1a0xQDEwtI8e9q6oVqCKB5sBp6kQNrCn8mBZqa417ZDd6Nqx1cIFeDdEbQal0JhI' +
        'K6ENGzSoCrq8zjWkLr7j6eNDY9ksF0JtCJBIRRUkQzsD+rq/O6gag1j7CDsONdF6cGtgzee/vw3I1Ld78u6n8Hz' +
        'XqSQFQFFq2MzZJ+APbduagMeovWpJoxRmd6QoIz1n72gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==';

      const TokenAccountBase64Data = 'xvp6877brTo9ZfNqq8l0MbG75MLS9uDkfKYCA0UvXWHNJBL0P4e2HX6CpWl/KIRDlySyNa+DGj4ekBShq/bWrw' +
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

      const TokenMintAccountBase64Data = 'AQAAABzjWe1aAS4E+hQrnHUaHF6Hz9CgFhuchf/TG3jN/Nj2du5fou7/EAAGAQEAAAAqnl7btTwEZ5CY/3sSZRcUQ0/AjFYqmjuGEQXmctQicw==';

    class function TokenProgramIdBytes: TBytes; static;

    class function ExpectedTransferData: TBytes; static;
    class function ExpectedTransferCheckedData: TBytes; static;
    class function ExpectedInitializeMintData: TBytes; static;
    class function ExpectedInitializeMultiSignatureData: TBytes; static;
    class function ExpectedMintToData: TBytes; static;
    class function ExpectedMintToCheckedData: TBytes; static;
    class function ExpectedBurnData: TBytes; static;
    class function ExpectedBurnCheckedData: TBytes; static;
    class function ExpectedInitializeAccountData: TBytes; static;
    class function ExpectedApproveData: TBytes; static;
    class function ExpectedApproveCheckedData: TBytes; static;
    class function ExpectedRevokeData: TBytes; static;
    class function ExpectedSetAuthorityOwnerData: TBytes; static;
    class function ExpectedSetAuthorityCloseData: TBytes; static;
    class function ExpectedSetAuthorityFreezeData: TBytes; static;
    class function ExpectedSetAuthorityMintData: TBytes; static;
    class function ExpectedCloseAccountData: TBytes; static;
    class function ExpectedFreezeAccountData: TBytes; static;
    class function ExpectedThawAccountData: TBytes; static;
    class function ExpectedSyncNativeData: TBytes; static;

  published
    procedure TestTransfer;
    procedure TestTransferChecked;
    procedure TestTransferCheckedMultiSignature;

    procedure TestInitializeAccount;
    procedure TestInitializeMint;
    procedure TestInitializeMultisig;

    procedure TestMintTo;
    procedure TestMintToChecked;
    procedure TestMintToCheckedMultiSignature;

    procedure TestBurn;
    procedure TestBurnChecked;
    procedure TestBurnMultiSignature;
    procedure TestBurnCheckedMultiSignature;

    procedure TestApprove;
    procedure TestApproveMultiSignature;
    procedure TestApproveChecked;
    procedure TestApproveCheckedMultiSignature;

    procedure TestRevoke;
    procedure TestRevokeMultiSignature;

    procedure TestSetAuthorityOwner;
    procedure TestSetAuthorityOwnerMultiSignature;
    procedure TestSetAuthorityClose;
    procedure TestSetAuthorityFreeze;
    procedure TestSetAuthorityMint;

    procedure TestCloseAccount;
    procedure TestCloseAccountMultiSignature;
    procedure TestFreezeAccount;
    procedure TestFreezeAccountMultiSignature;
    procedure TestThawAccount;
    procedure TestThawAccountMultiSignature;

    procedure TestSyncNative;

    procedure TestInitializeMultisigDecode;
    procedure TestMintToMultisigDecode;
    procedure TestDecodeMintToCheckedMessage;
    procedure TestDecodeTransferChecked;
    procedure TestDecodeBurnChecked;
    procedure TestDecodeFreezeAccount;
    procedure TestDecodeThawAccountAndSetAuthority;
    procedure TestDecodeApproveCheckedMultisig;
    procedure TestDecodeApproveMultisig;
    procedure TestDecodeTransferMultisig;
    procedure TestDecodeBurn;
    procedure TestDecodeBurnMultisig;
    procedure TestDecodeBurnCheckedMultisig;
    procedure TestDecodeRevokeMultisig;
    procedure TestDecodeBurnCheckedAndCloseMultisig;

    procedure TestMultiSignatureAccountDeserialization;
    procedure TestTokenAccountDeserialization;
    procedure TestTokenMintAccountDeserialization;

    procedure TestDecodeInitAccount3;
  end;

implementation

{ TTokenProgramTests }

class function TTokenProgramTests.TokenProgramIdBytes: TBytes;
begin
  Result := TBytes.Create(
    6, 221, 246, 225, 215, 101, 161, 147, 217, 203,
    225, 70, 206, 235, 121, 172, 28, 180, 133, 237,
    95, 91, 55, 145, 58, 140, 245, 133, 126, 255, 0, 169
  );
end;

class function TTokenProgramTests.ExpectedTransferData: TBytes;
begin
  Result := TBytes.Create(3, 168, 97, 0, 0, 0, 0, 0, 0);
end;

class function TTokenProgramTests.ExpectedTransferCheckedData: TBytes;
begin
  Result := TBytes.Create(12, 168, 97, 0, 0, 0, 0, 0, 0, 2);
end;

class function TTokenProgramTests.ExpectedInitializeMintData: TBytes;
begin
  Result := TBytes.Create(
    0, 2, 71, 105, 171, 151, 32, 75, 168, 63, 176, 202, 238, 23, 247, 134, 143, 30, 7, 78, 82, 21, 129,
    160, 216, 157, 148, 55, 157, 170, 101, 183, 23, 178, 1, 71, 105, 171, 151, 32, 75, 168, 63, 176,
    202, 238, 23, 247, 134, 143, 30, 7, 78, 82, 21, 129, 160, 216, 157, 148, 55, 157, 170, 101, 183, 23, 178
  );
end;

class function TTokenProgramTests.ExpectedInitializeMultiSignatureData: TBytes;
begin
  Result := TBytes.Create(2, 3);
end;

class function TTokenProgramTests.ExpectedMintToData: TBytes;
begin
  Result := TBytes.Create(7, 168, 97, 0, 0, 0, 0, 0, 0);
end;

class function TTokenProgramTests.ExpectedMintToCheckedData: TBytes;
begin
  Result := TBytes.Create(14, 168, 97, 0, 0, 0, 0, 0, 0,2);
end;

class function TTokenProgramTests.ExpectedBurnData: TBytes;
begin
  Result := TBytes.Create(8, 168, 97, 0, 0, 0, 0, 0, 0);
end;

class function TTokenProgramTests.ExpectedBurnCheckedData: TBytes;
begin
  Result := TBytes.Create(15, 168, 97, 0, 0, 0, 0, 0, 0,2);
end;

class function TTokenProgramTests.ExpectedInitializeAccountData: TBytes;
begin
  Result := TBytes.Create(1);
end;

class function TTokenProgramTests.ExpectedApproveData: TBytes;
begin
  Result := TBytes.Create(4, 168, 97, 0, 0, 0, 0, 0, 0);
end;

class function TTokenProgramTests.ExpectedApproveCheckedData: TBytes;
begin
  Result := TBytes.Create(13, 168, 97, 0, 0, 0, 0, 0, 0, 2);
end;

class function TTokenProgramTests.ExpectedRevokeData: TBytes;
begin
  Result := TBytes.Create(5);
end;

class function TTokenProgramTests.ExpectedSetAuthorityOwnerData: TBytes;
begin
  Result := TBytes.Create(
    6, 2, 1, 33, 79, 28, 109, 23, 45, 121, 163, 226, 87, 237, 185,
    47, 29, 248, 108, 218, 51, 132, 22, 227, 114, 38, 230, 154, 241, 16,
    104, 196, 10, 219, 24
  );
end;

class function TTokenProgramTests.ExpectedSetAuthorityCloseData: TBytes;
begin
  Result := TBytes.Create(
    6, 3, 1, 33, 79, 28, 109, 23, 45, 121, 163, 226, 87, 237, 185,
    47, 29, 248, 108, 218, 51, 132, 22, 227, 114, 38, 230, 154, 241, 16,
    104, 196, 10, 219, 24
  );
end;

class function TTokenProgramTests.ExpectedSetAuthorityFreezeData: TBytes;
begin
  Result := TBytes.Create(
    6, 1, 1, 33, 79, 28, 109, 23, 45, 121, 163, 226, 87, 237, 185,
    47, 29, 248, 108, 218, 51, 132, 22, 227, 114, 38, 230, 154, 241, 16,
    104, 196, 10, 219, 24
  );
end;

class function TTokenProgramTests.ExpectedSetAuthorityMintData: TBytes;
begin
  Result := TBytes.Create(
    6, 0, 1, 33, 79, 28, 109, 23, 45, 121, 163, 226, 87, 237, 185,
    47, 29, 248, 108, 218, 51, 132, 22, 227, 114, 38, 230, 154, 241, 16,
    104, 196, 10, 219, 24
  );
end;

class function TTokenProgramTests.ExpectedCloseAccountData: TBytes;
begin
  Result := TBytes.Create(9);
end;

class function TTokenProgramTests.ExpectedFreezeAccountData: TBytes;
begin
  Result := TBytes.Create(10);
end;

class function TTokenProgramTests.ExpectedThawAccountData: TBytes;
begin
  Result := TBytes.Create(11);
end;

class function TTokenProgramTests.ExpectedSyncNativeData: TBytes;
begin
  Result := TBytes.Create(17);
end;

procedure TTokenProgramTests.TestTransfer;
var
  Wallet: IWallet;
  Owner, Initial, New: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet  := TWallet.Create(MnemonicWords);
  Owner   := Wallet.GetAccountByIndex(10);
  Initial := Wallet.GetAccountByIndex(24);
  New     := Wallet.GetAccountByIndex(26);

  TxInstruction := TTokenProgram.Transfer(
              Initial.PublicKey,
              New.PublicKey,
              25000,
              Owner.PublicKey
            );

  AssertEquals(3, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedTransferData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestTransferChecked;
var
  Wallet: IWallet;
  Mint, Owner, Initial, New: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Initial    := Wallet.GetAccountByIndex(26);
  New    := Wallet.GetAccountByIndex(27);

  TxInstruction := TTokenProgram.TransferChecked(
              Initial.PublicKey,
              New.PublicKey,
              25000,
              2,
              Owner.PublicKey,
              Mint.PublicKey
            );

  AssertEquals(4, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedTransferCheckedData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestTransferCheckedMultiSignature;
var
  Wallet  : IWallet;
  Mint, Owner, Initial, New: IAccount;
  Signers: TList<IPublicKey>;
  TxInstruction: ITransactionInstruction;
  I: Integer;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Initial    := Wallet.GetAccountByIndex(26);
  New    := Wallet.GetAccountByIndex(27);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

    TxInstruction := TTokenProgram.TransferChecked(
                Initial.PublicKey, New.PublicKey, 25000, 2, Owner.PublicKey, Mint.PublicKey, Signers.ToArray
              );

    AssertEquals(9, TxInstruction.Keys.Count, 'Keys.Count mismatch');
    AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
    AssertEquals<Byte>(ExpectedTransferCheckedData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestInitializeAccount;
var
  Wallet: IWallet;
  Mint, Owner, Initial: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Initial   := Wallet.GetAccountByIndex(22);

  TxInstruction := TTokenProgram.InitializeAccount(
              Initial.PublicKey, Mint.PublicKey, Owner.PublicKey
            );

  AssertEquals(4, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedInitializeAccountData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestInitializeMint;
var
  Wallet: IWallet;
  Mint, Owner: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);

  TxInstruction := TTokenProgram.InitializeMint(
              Mint.PublicKey, 2, Owner.PublicKey, Owner.PublicKey
            );

  AssertEquals(2, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedInitializeMintData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestInitializeMultisig;
var
  Wallet: IWallet;
  MultiSig: IAccount;
  Signers: TList<IPublicKey>;
  I: Integer;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  MultiSig  := Wallet.GetAccountByIndex(420);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

    TxInstruction := TTokenProgram.InitializeMultiSignature(MultiSig.PublicKey, Signers.ToArray, 3);

    AssertEquals(7, TxInstruction.Keys.Count, 'Keys.Count mismatch');
    AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
    AssertEquals<Byte>(ExpectedInitializeMultiSignatureData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestMintTo;
var
  Wallet: IWallet;
  Mint, Owner, Initial: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Initial   := Wallet.GetAccountByIndex(22);

  TxInstruction := TTokenProgram.MintTo(
              Mint.PublicKey, Initial.PublicKey, 25000, Owner.PublicKey
            );

  AssertEquals(3, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedMintToData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestMintToChecked;
var
  Wallet: IWallet;
  Mint, Owner, Initial: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Initial   := Wallet.GetAccountByIndex(22);

  TxInstruction := TTokenProgram.MintToChecked(
              Mint.PublicKey, Initial.PublicKey, Owner.PublicKey, 25000, 2
            );

  AssertEquals(3, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedMintToCheckedData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestMintToCheckedMultiSignature;
var
  Wallet: IWallet;
  Mint, Owner, Initial: IAccount;
  Signers : TList<IPublicKey>;
  TxInstruction: ITransactionInstruction;
  I: Integer;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Initial   := Wallet.GetAccountByIndex(22);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

    TxInstruction := TTokenProgram.MintToChecked(
                Mint.PublicKey, Initial.PublicKey, Owner.PublicKey, 25000, 2, Signers.ToArray
              );

    AssertEquals(8, TxInstruction.Keys.Count, 'Keys.Count mismatch');
    AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
    AssertEquals<Byte>(ExpectedMintToCheckedData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestBurn;
var
  Wallet: IWallet;
  Mint, Owner, Initial: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Initial   := Wallet.GetAccountByIndex(22);

  TxInstruction := TTokenProgram.Burn(
              Initial.PublicKey, Mint.PublicKey, 25000, Owner.PublicKey
            );

  AssertEquals(3, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedBurnData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestBurnChecked;
var
  Wallet: IWallet;
  Mint, Owner, Initial: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Initial   := Wallet.GetAccountByIndex(22);

  TxInstruction := TTokenProgram.BurnChecked(
              Mint.PublicKey, Initial.PublicKey, Owner.PublicKey, 25000, 2
            );

  AssertEquals(3, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedBurnCheckedData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestBurnMultiSignature;
var
  Wallet: IWallet;
  Mint, Owner, Initial: IAccount;
  Signers : TList<IPublicKey>;
  TxInstruction: ITransactionInstruction;
  I: Integer;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Initial   := Wallet.GetAccountByIndex(22);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

    TxInstruction := TTokenProgram.Burn(
                Initial.PublicKey, Mint.PublicKey, 25000, Owner.PublicKey, Signers.ToArray
              );

    AssertEquals(8, TxInstruction.Keys.Count, 'Keys.Count mismatch');
    AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
    AssertEquals<Byte>(ExpectedBurnData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestBurnCheckedMultiSignature;
var
  Wallet: IWallet;
  Mint, Owner, Initial: IAccount;
  Signers : TList<IPublicKey>;
  TxInstruction: ITransactionInstruction;
  I: Integer;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Initial   := Wallet.GetAccountByIndex(22);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

    TxInstruction := TTokenProgram.BurnChecked(
                Mint.PublicKey, Initial.PublicKey, Owner.PublicKey, 25000, 2, Signers.ToArray
              );

    AssertEquals(8, TxInstruction.Keys.Count, 'Keys.Count mismatch');
    AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
    AssertEquals<Byte>(ExpectedBurnCheckedData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestApprove;
var
  Wallet: IWallet;
  Source, Delegate, Owner: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet   := TWallet.Create(MnemonicWords);
  Source   := Wallet.GetAccountByIndex(69);
  Delegate := Wallet.GetAccountByIndex(420);
  Owner    := Wallet.GetAccountByIndex(1);

  TxInstruction := TTokenProgram.Approve(
              Source.PublicKey, Delegate.PublicKey, Owner.PublicKey, 25000
            );

  AssertEquals(3, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedApproveData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestApproveMultiSignature;
var
  Wallet: IWallet;
  Source, Delegate, Owner: IAccount;
  Signers: TList<IPublicKey>;
  TxInstruction: ITransactionInstruction;
  I: Integer;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Source   := Wallet.GetAccountByIndex(69);
  Delegate  := Wallet.GetAccountByIndex(420);
  Owner   := Wallet.GetAccountByIndex(1);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

    TxInstruction := TTokenProgram.Approve(
                Source.PublicKey, Delegate.PublicKey, Owner.PublicKey, 25000, Signers.ToArray
              );

    AssertEquals(8, TxInstruction.Keys.Count, 'Keys.Count mismatch');
    AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
    AssertEquals<Byte>(ExpectedApproveData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestApproveChecked;
var
  Wallet: IWallet;
  Mint: IAccount;
  Source, Delegate, Owner: IAccount;
  Signers: TList<IPublicKey>;
  TxInstruction: ITransactionInstruction;
  I: Integer;
begin
  Wallet   := TWallet.Create(MnemonicWords);
  Mint     := Wallet.GetAccountByIndex(21);
  Source   := Wallet.GetAccountByIndex(69);
  Delegate := Wallet.GetAccountByIndex(420);
  Owner    := Wallet.GetAccountByIndex(1);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

    TxInstruction := TTokenProgram.ApproveChecked(
                Source.PublicKey, Delegate.PublicKey, 25000, 2, Owner.PublicKey, Mint.PublicKey, Signers.ToArray
              );

    AssertEquals(9, TxInstruction.Keys.Count, 'Keys.Count mismatch');
    AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
    AssertEquals<Byte>(ExpectedApproveCheckedData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestApproveCheckedMultiSignature;
var
  Wallet: IWallet;
  Mint, Source, Delegate, Owner: IAccount;
  Signers: TList<IPublicKey>;
  TxInstruction: ITransactionInstruction;
  I: Integer;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint     := Wallet.GetAccountByIndex(21);
  Source   := Wallet.GetAccountByIndex(69);
  Delegate  := Wallet.GetAccountByIndex(420);
  Owner   := Wallet.GetAccountByIndex(1);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

    TxInstruction := TTokenProgram.ApproveChecked(
                Source.PublicKey, Delegate.PublicKey, 25000, 2, Owner.PublicKey, Mint.PublicKey, Signers.ToArray
              );

    AssertEquals(9, TxInstruction.Keys.Count, 'Keys.Count mismatch');
    AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
    AssertEquals<Byte>(ExpectedApproveCheckedData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestRevoke;
var
  Wallet: IWallet;
  Delegate, Owner: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet   := TWallet.Create(MnemonicWords);
  Delegate := Wallet.GetAccountByIndex(420);
  Owner    := Wallet.GetAccountByIndex(1);

  TxInstruction := TTokenProgram.Revoke(
              Delegate.PublicKey, Owner.PublicKey
            );

  AssertEquals(2, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedRevokeData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestRevokeMultiSignature;
var
  Wallet: IWallet;
  Delegate, Owner: IAccount;
  Signers: TList<IPublicKey>;
  TxInstruction: ITransactionInstruction;
  I: Integer;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Delegate  := Wallet.GetAccountByIndex(420);
  Owner   := Wallet.GetAccountByIndex(1);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

    TxInstruction := TTokenProgram.Revoke(
                Delegate.PublicKey, Owner.PublicKey, Signers.ToArray
              );

    AssertEquals(7, TxInstruction.Keys.Count, 'Keys.Count mismatch');
    AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
    AssertEquals<Byte>(ExpectedRevokeData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestSetAuthorityOwner;
var
  Wallet: IWallet;
  Account, CurrentOwner, NewOwner: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Account   := Wallet.GetAccountByIndex(1000);
  CurrentOwner  := Wallet.GetAccountByIndex(1);
  NewOwner    := Wallet.GetAccountByIndex(2);

  TxInstruction := TTokenProgram.SetAuthority(
              Account.PublicKey, TAuthorityType.AccountOwner, CurrentOwner.PublicKey, NewOwner.PublicKey
            );

  AssertEquals(2, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedSetAuthorityOwnerData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestSetAuthorityOwnerMultiSignature;
var
  Wallet: IWallet;
  Account, CurrentOwner, NewOwner: IAccount;
  Signers: TList<IPublicKey>;
  TxInstruction: ITransactionInstruction;
  I: Integer;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Account   := Wallet.GetAccountByIndex(1000);
  CurrentOwner  := Wallet.GetAccountByIndex(1);
  NewOwner    := Wallet.GetAccountByIndex(2);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

  TxInstruction := TTokenProgram.SetAuthority(
              Account.PublicKey, TAuthorityType.AccountOwner, CurrentOwner.PublicKey, NewOwner.PublicKey, Signers.ToArray
            );

  AssertEquals(7, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedSetAuthorityOwnerData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestSetAuthorityClose;
var
  Wallet: IWallet;
  Account, CurrentOwner, NewOwner: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Account   := Wallet.GetAccountByIndex(1000);
  CurrentOwner  := Wallet.GetAccountByIndex(1);
  NewOwner    := Wallet.GetAccountByIndex(2);

  TxInstruction := TTokenProgram.SetAuthority(
              Account.PublicKey, TAuthorityType.CloseAccount, CurrentOwner.PublicKey, NewOwner.PublicKey
            );

  AssertEquals(2, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedSetAuthorityCloseData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestSetAuthorityFreeze;
var
  Wallet: IWallet;
  Account, CurrentOwner, NewOwner: IAccount;
  TxInstruction  : ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Account   := Wallet.GetAccountByIndex(1000);
  CurrentOwner  := Wallet.GetAccountByIndex(1);
  NewOwner    := Wallet.GetAccountByIndex(2);

  TxInstruction := TTokenProgram.SetAuthority(
              Account.PublicKey, TAuthorityType.FreezeAccount, CurrentOwner.PublicKey, NewOwner.PublicKey
            );

  AssertEquals(2, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedSetAuthorityFreezeData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestSetAuthorityMint;
var
  Wallet: IWallet;
  Account, CurrentOwner, NewOwner: IAccount;
  TxInstruction  : ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Account   := Wallet.GetAccountByIndex(1000);
  CurrentOwner  := Wallet.GetAccountByIndex(1);
  NewOwner    := Wallet.GetAccountByIndex(2);

  TxInstruction := TTokenProgram.SetAuthority(
              Account.PublicKey, TAuthorityType.MintTokens, CurrentOwner.PublicKey, NewOwner.PublicKey
            );

  AssertEquals(2, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedSetAuthorityMintData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestCloseAccount;
var
  Wallet: IWallet;
  Owner, Account: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Owner  := Wallet.GetAccountByIndex(10);
  Account   := Wallet.GetAccountByIndex(22);

  TxInstruction := TTokenProgram.CloseAccount(
              Account.PublicKey, Owner.PublicKey, Owner.PublicKey, TTokenProgram.ProgramIdKey
            );

  AssertEquals(3, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedCloseAccountData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestCloseAccountMultiSignature;
var
  Wallet: IWallet;
  Owner, Account: IAccount;
  Signers: TList<IPublicKey>;
  TxInstruction: ITransactionInstruction;
  I: Integer;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Owner  := Wallet.GetAccountByIndex(10);
  Account   := Wallet.GetAccountByIndex(22);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

  TxInstruction := TTokenProgram.CloseAccount(
              Account.PublicKey, Owner.PublicKey, Owner.PublicKey, TTokenProgram.ProgramIdKey, Signers.ToArray
            );

  AssertEquals(8, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedCloseAccountData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestFreezeAccount;
var
  Wallet: IWallet;
  Mint, Owner, Account: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Account   := Wallet.GetAccountByIndex(22);

  TxInstruction := TTokenProgram.FreezeAccount(
              Account.PublicKey, Mint.PublicKey, Owner.PublicKey, TTokenProgram.ProgramIdKey
            );

  AssertEquals(3, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedFreezeAccountData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestFreezeAccountMultiSignature;
var
  Wallet: IWallet;
  Mint, Owner, Account: IAccount;
  Signers: TList<IPublicKey>;
  TxInstruction: ITransactionInstruction;
  I: Integer;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Account   := Wallet.GetAccountByIndex(22);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

    TxInstruction := TTokenProgram.FreezeAccount(
                Account.PublicKey, Mint.PublicKey, Owner.PublicKey, TTokenProgram.ProgramIdKey, Signers.ToArray
              );

    AssertEquals(8, TxInstruction.Keys.Count, 'Keys.Count mismatch');
    AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
    AssertEquals<Byte>(ExpectedFreezeAccountData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestThawAccount;
var
  Wallet: IWallet;
  Mint, Owner, Account: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Account   := Wallet.GetAccountByIndex(22);

  TxInstruction := TTokenProgram.ThawAccount(
              Account.PublicKey, Mint.PublicKey, Owner.PublicKey, TTokenProgram.ProgramIdKey
            );

  AssertEquals(3, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedThawAccountData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestThawAccountMultiSignature;
var
  Wallet: IWallet;
  Mint, Owner, Account: IAccount;
  Signers: TList<IPublicKey>;
  TxInstruction: ITransactionInstruction;
  I: Integer;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Mint   := Wallet.GetAccountByIndex(21);
  Owner  := Wallet.GetAccountByIndex(10);
  Account   := Wallet.GetAccountByIndex(22);

  Signers := TList<IPublicKey>.Create;
  try
    for I := 0 to 4 do
      Signers.Add(Wallet.GetAccountByIndex(420 + I).PublicKey);

    TxInstruction := TTokenProgram.ThawAccount(
                Account.PublicKey, Mint.PublicKey, Owner.PublicKey, TTokenProgram.ProgramIdKey, Signers.ToArray
              );

    AssertEquals(8, TxInstruction.Keys.Count, 'Keys.Count mismatch');
    AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
    AssertEquals<Byte>(ExpectedThawAccountData, TxInstruction.Data, 'Data mismatch');
  finally
    Signers.Free;
  end;
end;

procedure TTokenProgramTests.TestSyncNative;
var
  Wallet: IWallet;
  Account: IAccount;
  TxInstruction: ITransactionInstruction;
begin
  Wallet := TWallet.Create(MnemonicWords);
  Account   := Wallet.GetAccountByIndex(212);

  TxInstruction := TTokenProgram.SyncNative(Account.PublicKey);

  AssertEquals(1, TxInstruction.Keys.Count, 'Keys.Count mismatch');
  AssertEquals<Byte>(TokenProgramIdBytes, TxInstruction.ProgramId, 'ProgramId mismatch');
  AssertEquals<Byte>(ExpectedSyncNativeData, TxInstruction.Data, 'Data mismatch');
end;

procedure TTokenProgramTests.TestInitializeMultisigDecode;
var
  LMsg      : IMessage;
  LDecoded  : TList<IDecodedInstruction>;
  LVal      : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(InitializeMultisigMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // assert: overall
    AssertEquals(5, LDecoded.Count, 'Decoded instruction count');

    //
    // Instruction 0 - System Program: Create Account
    //
    AssertEquals('Create Account', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('System Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('11111111111111111111111111111111', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Owner Account', LVal), 'I0 missing "Owner Account"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I0 Owner Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('New Account', LVal), 'I0 missing "New Account"');
    AssertEquals('987cq6uofpTKzTyQywsyqNNyAKHAkJkBvY6ggqPnS8gJ', LVal.AsType<IPublicKey>.Key, 'I0 New Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('Amount', LVal), 'I0 missing "Amount"');
    AssertEquals(3361680, LVal.AsType<UInt64>, 'I0 Amount (lamports)');

    AssertTrue(LDecoded[0].Values.TryGetValue('Space', LVal), 'I0 missing "Space"');
    AssertEquals(355, LVal.AsType<UInt64>, 'I0 Space (bytes)');

    //
    // Instruction 1 - Token Program: Initialize Multisig
    //
    AssertEquals('Initialize Multisig', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('Token Program', LDecoded[1].ProgramName, 'I1 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertTrue(LDecoded[1].Values.TryGetValue('Account', LVal), 'I1 missing "Account"');
    AssertEquals('987cq6uofpTKzTyQywsyqNNyAKHAkJkBvY6ggqPnS8gJ', LVal.AsType<IPublicKey>.Key, 'I1 Account');

    AssertTrue(LDecoded[1].Values.TryGetValue('Required Signers', LVal), 'I1 missing "Required Signers"');
    AssertEquals(3, LVal.AsType<Byte>, 'I1 Required Signers');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 1', LVal), 'I1 missing "Signer 1"');
    AssertEquals('DjhLN52wpL6aw9k65MHb3jwxQ7fZ7gfMUGK3gHMBQPWa', LVal.AsType<IPublicKey>.Key, 'I1 Signer 1');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 2', LVal), 'I1 missing "Signer 2"');
    AssertEquals('4h47wFJ7dheVfJJrEcQfx5HvsP3PsfxEqaN38E6pSfhd', LVal.AsType<IPublicKey>.Key, 'I1 Signer 2');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 3', LVal), 'I1 missing "Signer 3"');
    AssertEquals('4gMxwYxoxbSekFNEUtUFfWECF5cp2FRGughfMx22ivwe', LVal.AsType<IPublicKey>.Key, 'I1 Signer 3');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 4', LVal), 'I1 missing "Signer 4"');
    AssertEquals('5BYjVTAYDrRQpMCP4zML3X2v6Jde1sHx3a1bd6DRskVJ', LVal.AsType<IPublicKey>.Key, 'I1 Signer 4');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 5', LVal), 'I1 missing "Signer 5"');
    AssertEquals('AKWjVdBUvekPc2bGf6gKAbQNRSfiXVZ3qFVnP6W8p1W8', LVal.AsType<IPublicKey>.Key, 'I1 Signer 5');

    //
    // Instruction 3 - Token Program: Initialize Mint
    // (index 2 is the Rent sysvar account)
    //
    AssertEquals('Initialize Mint', LDecoded[3].InstructionName, 'I3 name');
    AssertEquals('Token Program', LDecoded[3].ProgramName, 'I3 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[3].PublicKey.Key, 'I3 program id');
    AssertEquals(0, LDecoded[3].InnerInstructions.Count, 'I3 inner count');

    AssertTrue(LDecoded[3].Values.TryGetValue('Account', LVal), 'I3 missing "Account"');
    AssertEquals('HUATcRqk8qaNHTfRjBePt9mUZ16dDN1cbpWQDk7QFUGm', LVal.AsType<IPublicKey>.Key, 'I3 Account');

    AssertTrue(LDecoded[3].Values.TryGetValue('Decimals', LVal), 'I3 missing "Decimals"');
    AssertEquals(10, LVal.AsType<Byte>, 'I3 Decimals');

    AssertTrue(LDecoded[3].Values.TryGetValue('Mint Authority', LVal), 'I3 missing "Mint Authority"');
    AssertEquals('987cq6uofpTKzTyQywsyqNNyAKHAkJkBvY6ggqPnS8gJ', LVal.AsType<IPublicKey>.Key, 'I3 Mint Authority');

    AssertTrue(LDecoded[3].Values.TryGetValue('Freeze Authority Option', LVal), 'I3 missing "Freeze Authority Option"');
    AssertFalse(LVal.AsType<Boolean>, 'I3 Freeze Authority Option');

    // omit "Freeze Authority" when option = false; we assert it's absent.
    AssertFalse(LDecoded[3].Values.TryGetValue('Freeze Authority', LVal), 'I3 "Freeze Authority" should be absent');
    AssertNull(LVal.AsType<IPublicKey>, 'I3 Freeze Authority should be absent when option = false');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestMintToMultisigDecode;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(MintToMultisigMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // assert
    AssertEquals(4, LDecoded.Count, 'Decoded instruction count');

    //
    // Instruction 0 - System Program: Create Account
    //
    AssertEquals('Create Account', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('System Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('11111111111111111111111111111111', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Owner Account', LVal), 'I0 missing "Owner Account"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I0 Owner Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('New Account', LVal), 'I0 missing "New Account"');
    AssertEquals('z2qF2eWM89sQrXP2ygrLkYkhc58182KqPVRETjv8Dch', LVal.AsType<IPublicKey>.Key, 'I0 New Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('Amount', LVal), 'I0 missing "Amount"');
    AssertEquals(2039280, LVal.AsType<UInt64>, 'I0 Amount (lamports)');

    AssertTrue(LDecoded[0].Values.TryGetValue('Space', LVal), 'I0 missing "Space"');
    AssertEquals(165, LVal.AsType<UInt64>, 'I0 Space (bytes)');

    //
    // Instruction 1 - Token Program: Initialize Account
    //
    AssertEquals('Initialize Account', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('Token Program', LDecoded[1].ProgramName, 'I1 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertTrue(LDecoded[1].Values.TryGetValue('Account', LVal), 'I1 missing "Account"');
    AssertEquals('z2qF2eWM89sQrXP2ygrLkYkhc58182KqPVRETjv8Dch', LVal.AsType<IPublicKey>.Key, 'I1 Account');

    AssertTrue(LDecoded[1].Values.TryGetValue('Authority', LVal), 'I1 missing "Authority"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I1 Authority');

    AssertTrue(LDecoded[1].Values.TryGetValue('Mint', LVal), 'I1 missing "Mint"');
    AssertEquals('HUATcRqk8qaNHTfRjBePt9mUZ16dDN1cbpWQDk7QFUGm', LVal.AsType<IPublicKey>.Key, 'I1 Mint');

    //
    // Instruction 2 - Token Program: Mint To (Multisig)
    //
    AssertEquals('Mint To', LDecoded[2].InstructionName, 'I2 name');
    AssertEquals('Token Program', LDecoded[2].ProgramName, 'I2 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[2].PublicKey.Key, 'I2 program id');
    AssertEquals(0, LDecoded[2].InnerInstructions.Count, 'I2 inner count');

    AssertTrue(LDecoded[2].Values.TryGetValue('Mint Authority', LVal), 'I2 missing "Mint Authority"');
    AssertEquals('987cq6uofpTKzTyQywsyqNNyAKHAkJkBvY6ggqPnS8gJ', LVal.AsType<IPublicKey>.Key, 'I2 Mint Authority');

    AssertTrue(LDecoded[2].Values.TryGetValue('Destination', LVal), 'I2 missing "Destination"');
    AssertEquals('z2qF2eWM89sQrXP2ygrLkYkhc58182KqPVRETjv8Dch', LVal.AsType<IPublicKey>.Key, 'I2 Destination');

    AssertTrue(LDecoded[2].Values.TryGetValue('Amount', LVal), 'I2 missing "Amount"');
    AssertEquals(25000, LVal.AsType<UInt64>, 'I2 Amount (lamports)');

    AssertTrue(LDecoded[2].Values.TryGetValue('Mint', LVal), 'I2 missing "Mint"');
    AssertEquals('HUATcRqk8qaNHTfRjBePt9mUZ16dDN1cbpWQDk7QFUGm', LVal.AsType<IPublicKey>.Key, 'I2 Mint');

    AssertTrue(LDecoded[2].Values.TryGetValue('Signer 1', LVal), 'I2 missing "Signer 1"');
    AssertEquals('DjhLN52wpL6aw9k65MHb3jwxQ7fZ7gfMUGK3gHMBQPWa', LVal.AsType<IPublicKey>.Key, 'I2 Signer 1');

    AssertTrue(LDecoded[2].Values.TryGetValue('Signer 2', LVal), 'I2 missing "Signer 2"');
    AssertEquals('4h47wFJ7dheVfJJrEcQfx5HvsP3PsfxEqaN38E6pSfhd', LVal.AsType<IPublicKey>.Key, 'I2 Signer 2');

    AssertTrue(LDecoded[2].Values.TryGetValue('Signer 3', LVal), 'I2 missing "Signer 3"');
    AssertEquals('5BYjVTAYDrRQpMCP4zML3X2v6Jde1sHx3a1bd6DRskVJ', LVal.AsType<IPublicKey>.Key, 'I2 Signer 3');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeMintToCheckedMessage;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(MintToCheckedMultisigMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // assert
    AssertEquals(2, LDecoded.Count, 'Decoded instruction count');

    //
    // Instruction 0 - Token Program: Mint To Checked (Multisig)
    //
    AssertEquals('Mint To Checked', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('Token Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 1', LVal), 'I0 missing "Signer 1"');
    AssertEquals('DjhLN52wpL6aw9k65MHb3jwxQ7fZ7gfMUGK3gHMBQPWa', LVal.AsType<IPublicKey>.Key, 'I0 Signer 1');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 2', LVal), 'I0 missing "Signer 2"');
    AssertEquals('4h47wFJ7dheVfJJrEcQfx5HvsP3PsfxEqaN38E6pSfhd', LVal.AsType<IPublicKey>.Key, 'I0 Signer 2');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 3', LVal), 'I0 missing "Signer 3"');
    AssertEquals('5BYjVTAYDrRQpMCP4zML3X2v6Jde1sHx3a1bd6DRskVJ', LVal.AsType<IPublicKey>.Key, 'I0 Signer 3');

    AssertTrue(LDecoded[0].Values.TryGetValue('Destination', LVal), 'I0 missing "Destination"');
    AssertEquals('z2qF2eWM89sQrXP2ygrLkYkhc58182KqPVRETjv8Dch', LVal.AsType<IPublicKey>.Key, 'I0 Destination');

    AssertTrue(LDecoded[0].Values.TryGetValue('Amount', LVal), 'I0 missing "Amount"');
    AssertEquals(25000, LVal.AsType<UInt64>, 'I0 Amount (lamports)');

    AssertTrue(LDecoded[0].Values.TryGetValue('Decimals', LVal), 'I0 missing "Decimals"');
    AssertEquals(10, LVal.AsType<Byte>, 'I0 Decimals');

    AssertTrue(LDecoded[0].Values.TryGetValue('Mint', LVal), 'I0 missing "Mint"');
    AssertEquals('HUATcRqk8qaNHTfRjBePt9mUZ16dDN1cbpWQDk7QFUGm', LVal.AsType<IPublicKey>.Key, 'I0 Mint');

    AssertTrue(LDecoded[0].Values.TryGetValue('Mint Authority', LVal), 'I0 missing "Mint Authority"');
    AssertEquals('987cq6uofpTKzTyQywsyqNNyAKHAkJkBvY6ggqPnS8gJ', LVal.AsType<IPublicKey>.Key, 'I0 Mint Authority');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeTransferChecked;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(TransferCheckedMultisigMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // assert
    AssertEquals(1, LDecoded.Count, 'Decoded instruction count');

    //
    // Instruction 0 - Token Program: Transfer Checked (Multisig)
    //
    AssertEquals('Transfer Checked', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('Token Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 1', LVal), 'I0 missing "Signer 1"');
    AssertEquals('238y27qL4hnoqByugWhKDA76T7mXHdfK6Qv7fyFqqPYm', LVal.AsType<IPublicKey>.Key, 'I0 Signer 1');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 2', LVal), 'I0 missing "Signer 2"');
    AssertEquals('AJk1YpH1g4A3M4XA1UWbxzMVi6jzSVYBuaRhAkJxK1vH', LVal.AsType<IPublicKey>.Key, 'I0 Signer 2');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 3', LVal), 'I0 missing "Signer 3"');
    AssertEquals('HFgCrTmWC8KGxxSLXN8Xm4FVQU73FtoupdZNDRqfMtV3', LVal.AsType<IPublicKey>.Key, 'I0 Signer 3');

    AssertTrue(LDecoded[0].Values.TryGetValue('Destination', LVal), 'I0 missing "Destination"');
    AssertEquals('z2qF2eWM89sQrXP2ygrLkYkhc58182KqPVRETjv8Dch', LVal.AsType<IPublicKey>.Key, 'I0 Destination');

    AssertTrue(LDecoded[0].Values.TryGetValue('Source', LVal), 'I0 missing "Source"');
    AssertEquals('GPpAGnKUSE68JXMcJuws6WVVjTuGH4iqGu5FhbYT3Wk', LVal.AsType<IPublicKey>.Key, 'I0 Source');

    AssertTrue(LDecoded[0].Values.TryGetValue('Authority', LVal), 'I0 missing "Authority"');
    AssertEquals('GfYeo1qjCmpRY8nNoeCkNAyXAaecesCmLPorXTekkUKx', LVal.AsType<IPublicKey>.Key, 'I0 Authority');

    AssertTrue(LDecoded[0].Values.TryGetValue('Amount', LVal), 'I0 missing "Amount"');
    AssertEquals(10000, LVal.AsType<UInt64>, 'I0 Amount (lamports)');

    AssertTrue(LDecoded[0].Values.TryGetValue('Decimals', LVal), 'I0 missing "Decimals"');
    AssertEquals(10, LVal.AsType<Byte>, 'I0 Decimals');

    AssertTrue(LDecoded[0].Values.TryGetValue('Mint', LVal), 'I0 missing "Mint"');
    AssertEquals('HUATcRqk8qaNHTfRjBePt9mUZ16dDN1cbpWQDk7QFUGm', LVal.AsType<IPublicKey>.Key, 'I0 Mint');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeBurnChecked;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(BurnCheckedMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // assert
    AssertEquals(2, LDecoded.Count, 'Decoded instruction count');

    //
    // Instruction 0 - Token Program: Burn Checked
    //
    AssertEquals('Burn Checked', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('Token Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Account', LVal), 'I0 missing "Account"');
    AssertEquals('z2qF2eWM89sQrXP2ygrLkYkhc58182KqPVRETjv8Dch', LVal.AsType<IPublicKey>.Key, 'I0 Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('Mint', LVal), 'I0 missing "Mint"');
    AssertEquals('HUATcRqk8qaNHTfRjBePt9mUZ16dDN1cbpWQDk7QFUGm', LVal.AsType<IPublicKey>.Key, 'I0 Mint');

    AssertTrue(LDecoded[0].Values.TryGetValue('Authority', LVal), 'I0 missing "Authority"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I0 Authority');

    AssertTrue(LDecoded[0].Values.TryGetValue('Amount', LVal), 'I0 missing "Amount"');
    AssertEquals(25000, LVal.AsType<UInt64>, 'I0 Amount (lamports)');

    AssertTrue(LDecoded[0].Values.TryGetValue('Decimals', LVal), 'I0 missing "Decimals"');
    AssertEquals(10, LVal.AsType<Byte>, 'I0 Decimals');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeFreezeAccount;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(FreezeAccountMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // assert
    AssertEquals(2, LDecoded.Count, 'Decoded instruction count');

    //
    // Instruction 0 - Token Program: Freeze Account
    //
    AssertEquals('Freeze Account', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('Token Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Account', LVal), 'I0 missing "Account"');
    AssertEquals('5GB1nY6isABT3LzRfbvTYAQpwdSSLoGz88JV1y6PdRLG', LVal.AsType<IPublicKey>.Key, 'I0 Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('Mint', LVal), 'I0 missing "Mint"');
    AssertEquals('DEFFeVTB3ZKUFFncKn2L1jwW4MnLW8UJDkgxpiGRQtaD', LVal.AsType<IPublicKey>.Key, 'I0 Mint');

    AssertTrue(LDecoded[0].Values.TryGetValue('Freeze Authority', LVal), 'I0 missing "Freeze Authority"');
    AssertEquals('8yZoieywT6CtjK6puZXwg4RASSbQBX3cg9Dnx6LMUgd6', LVal.AsType<IPublicKey>.Key, 'I0 Freeze Authority');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 1', LVal), 'I0 missing "Signer 1"');
    AssertEquals('jk6EcAAv1t4o7Nd4cge3nkXWAmUEcg4HDVvew3szjWp', LVal.AsType<IPublicKey>.Key, 'I0 Signer 1');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 2', LVal), 'I0 missing "Signer 2"');
    AssertEquals('6dRt18mbEHu28fxdyXQGmnLvc9zrp8AsAfBW26vAxVTR', LVal.AsType<IPublicKey>.Key, 'I0 Signer 2');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 3', LVal), 'I0 missing "Signer 3"');
    AssertEquals('8GrcvhyiKdVk9DTYtKkW5qiiR74hevpiQQ1cFMFAmR3o', LVal.AsType<IPublicKey>.Key, 'I0 Signer 3');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeThawAccountAndSetAuthority;
var
  LMsg        : IMessage;
  LDecoded    : TList<IDecodedInstruction>;
  LVal        : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(ThawAccountSetAuthorityMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // assert
    AssertEquals(3, LDecoded.Count, 'Decoded instruction count');

    //
    // Instruction 0 - Token Program: Thaw Account
    //
    AssertEquals('Thaw Account', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('Token Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Account', LVal), 'I0 missing "Account"');
    AssertEquals('5GB1nY6isABT3LzRfbvTYAQpwdSSLoGz88JV1y6PdRLG', LVal.AsType<IPublicKey>.Key, 'I0 Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('Mint', LVal), 'I0 missing "Mint"');
    AssertEquals('DEFFeVTB3ZKUFFncKn2L1jwW4MnLW8UJDkgxpiGRQtaD', LVal.AsType<IPublicKey>.Key, 'I0 Mint');

    AssertTrue(LDecoded[0].Values.TryGetValue('Freeze Authority', LVal), 'I0 missing "Freeze Authority"');
    AssertEquals('8yZoieywT6CtjK6puZXwg4RASSbQBX3cg9Dnx6LMUgd6', LVal.AsType<IPublicKey>.Key, 'I0 Freeze Authority');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 1', LVal), 'I0 missing "Signer 1"');
    AssertEquals('jk6EcAAv1t4o7Nd4cge3nkXWAmUEcg4HDVvew3szjWp', LVal.AsType<IPublicKey>.Key, 'I0 Signer 1');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 2', LVal), 'I0 missing "Signer 2"');
    AssertEquals('6dRt18mbEHu28fxdyXQGmnLvc9zrp8AsAfBW26vAxVTR', LVal.AsType<IPublicKey>.Key, 'I0 Signer 2');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 3', LVal), 'I0 missing "Signer 3"');
    AssertEquals('8GrcvhyiKdVk9DTYtKkW5qiiR74hevpiQQ1cFMFAmR3o', LVal.AsType<IPublicKey>.Key, 'I0 Signer 3');

    //
    // Instruction 1 - Token Program: Set Authority
    //
    AssertEquals('Set Authority', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('Token Program', LDecoded[1].ProgramName, 'I1 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertTrue(LDecoded[1].Values.TryGetValue('Account', LVal), 'I1 missing "Account"');
    AssertEquals('DEFFeVTB3ZKUFFncKn2L1jwW4MnLW8UJDkgxpiGRQtaD', LVal.AsType<IPublicKey>.Key, 'I1 Account');

    AssertTrue(LDecoded[1].Values.TryGetValue('Authority Type', LVal), 'I1 missing "Authority Type"');
    AssertEquals(Ord(TAuthorityType.AccountOwner), Ord(LVal.AsType<TAuthorityType>), 'I1 Authority Type');

    AssertTrue(LDecoded[1].Values.TryGetValue('Current Authority', LVal), 'I1 missing "Current Authority"');
    AssertEquals('8yZoieywT6CtjK6puZXwg4RASSbQBX3cg9Dnx6LMUgd6', LVal.AsType<IPublicKey>.Key, 'I1 Current Authority');

    AssertTrue(LDecoded[1].Values.TryGetValue('New Authority Option', LVal), 'I1 missing "New Authority Option"');
    AssertEquals(1, LVal.AsType<Byte>, 'I1 New Authority Option');

    AssertTrue(LDecoded[1].Values.TryGetValue('New Authority', LVal), 'I1 missing "New Authority"');
    AssertEquals('Hv3ZhRpKPyLYAwQR2mTPFMYpAQvtwdxxCKKkEVTbrS4j', LVal.AsType<IPublicKey>.Key, 'I1 New Authority');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 1', LVal), 'I1 missing "Signer 1"');
    AssertEquals('jk6EcAAv1t4o7Nd4cge3nkXWAmUEcg4HDVvew3szjWp', LVal.AsType<IPublicKey>.Key, 'I1 Signer 1');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 2', LVal), 'I1 missing "Signer 2"');
    AssertEquals('6dRt18mbEHu28fxdyXQGmnLvc9zrp8AsAfBW26vAxVTR', LVal.AsType<IPublicKey>.Key, 'I1 Signer 2');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 3', LVal), 'I1 missing "Signer 3"');
    AssertEquals('8GrcvhyiKdVk9DTYtKkW5qiiR74hevpiQQ1cFMFAmR3o', LVal.AsType<IPublicKey>.Key, 'I1 Signer 3');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeApproveCheckedMultisig;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(ApproveCheckedMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // assert
    AssertEquals(2, LDecoded.Count, 'Decoded instruction count');

    //
    // Instruction 0 - Token Program: Approve Checked (Multisig)
    //
    AssertEquals('Approve Checked', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('Token Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Source', LVal), 'I0 missing "Source"');
    AssertEquals('CT5RqeDvgrU6NKeGm3f3GBkjAFsVzxusB6cq158nbZJe', LVal.AsType<IPublicKey>.Key, 'I0 Source');

    AssertTrue(LDecoded[0].Values.TryGetValue('Mint', LVal), 'I0 missing "Mint"');
    AssertEquals('HAbjCwXvJLRYPwsfLftT52iPYbHeGPyhPi3QCWiY2CTq', LVal.AsType<IPublicKey>.Key, 'I0 Mint');

    AssertTrue(LDecoded[0].Values.TryGetValue('Delegate', LVal), 'I0 missing "Delegate"');
    AssertEquals('Dx9YthDvULaC41tJcjJUEMXx7Ky5XQ7jcBx7FdWScCoM', LVal.AsType<IPublicKey>.Key, 'I0 Delegate');

    AssertTrue(LDecoded[0].Values.TryGetValue('Authority', LVal), 'I0 missing "Authority"');
    AssertEquals('3Gph2RRQBBQ9BRPHh6d5DNzfgHSWqM3sP4tdRZPRgWEQ', LVal.AsType<IPublicKey>.Key, 'I0 Authority');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 1', LVal), 'I0 missing "Signer 1"');
    AssertEquals('9y51foHfw4WzfMR69Tv9hMabAsUeMG8w8AYVpMToVBc9', LVal.AsType<IPublicKey>.Key, 'I0 Signer 1');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 2', LVal), 'I0 missing "Signer 2"');
    AssertEquals('8qpWzMaGsHxwjpv6awy7kqEuCGugGCv4S5BSidDCQ33a', LVal.AsType<IPublicKey>.Key, 'I0 Signer 2');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 3', LVal), 'I0 missing "Signer 3"');
    AssertEquals('DNE44u4kYtiswWUy91eEAypWfZoAhVPjqpQ8JxctY6qC', LVal.AsType<IPublicKey>.Key, 'I0 Signer 3');

    AssertTrue(LDecoded[0].Values.TryGetValue('Amount', LVal), 'I0 missing "Amount"');
    AssertEquals(5000, LVal.AsType<UInt64>, 'I0 Amount (lamports)');

    AssertTrue(LDecoded[0].Values.TryGetValue('Decimals', LVal), 'I0 missing "Decimals"');
    AssertEquals(10, LVal.AsType<Byte>, 'I0 Decimals');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeApproveMultisig;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(ApproveMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // assert
    AssertEquals(2, LDecoded.Count, 'Decoded instruction count');

    //
    // Instruction 0 - Token Program: Approve (Multisig)
    //
    AssertEquals('Approve', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('Token Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Source', LVal), 'I0 missing "Source"');
    AssertEquals('6EzHDa6PENJVi4iHFPXsThMQpcgQg7QiW4GJj4cyayCX', LVal.AsType<IPublicKey>.Key, 'I0 Source');

    AssertTrue(LDecoded[0].Values.TryGetValue('Delegate', LVal), 'I0 missing "Delegate"');
    AssertEquals('Dx9YthDvULaC41tJcjJUEMXx7Ky5XQ7jcBx7FdWScCoM', LVal.AsType<IPublicKey>.Key, 'I0 Delegate');

    AssertTrue(LDecoded[0].Values.TryGetValue('Authority', LVal), 'I0 missing "Authority"');
    AssertEquals('J7UXZmSDpp4XbQkwqSxqyRvUb6DJ2SEFhmn3t38KsHu3', LVal.AsType<IPublicKey>.Key, 'I0 Authority');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 1', LVal), 'I0 missing "Signer 1"');
    AssertEquals('3KPXPJx2U4czq13Dp5E7uw8NutLphpa3EAaUZZuVoxzQ', LVal.AsType<IPublicKey>.Key, 'I0 Signer 1');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 2', LVal), 'I0 missing "Signer 2"');
    AssertEquals('5pwGNb7apN4VBHxXcr9428RDSzyMer3YYcQtLFjMzqX9', LVal.AsType<IPublicKey>.Key, 'I0 Signer 2');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 3', LVal), 'I0 missing "Signer 3"');
    AssertEquals('BRp1JDyCy4xzS77xTjB14mimRhSTBZtaHer5LuueAyTA', LVal.AsType<IPublicKey>.Key, 'I0 Signer 3');

    AssertTrue(LDecoded[0].Values.TryGetValue('Amount', LVal), 'I0 missing "Amount"');
    AssertEquals(5000, LVal.AsType<UInt64>, 'I0 Amount (lamports)');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeTransferMultisig;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(TransferMultisigMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // assert
    AssertEquals(1, LDecoded.Count, 'Decoded instruction count');

    //
    // Instruction 0 - Token Program: Transfer (Multisig)
    //
    AssertEquals('Transfer', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('Token Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Destination', LVal), 'I0 missing "Destination"');
    AssertEquals('z2qF2eWM89sQrXP2ygrLkYkhc58182KqPVRETjv8Dch', LVal.AsType<IPublicKey>.Key, 'I0 Destination');

    AssertTrue(LDecoded[0].Values.TryGetValue('Source', LVal), 'I0 missing "Source"');
    AssertEquals('4sW9XdttQsm1QrfQoRW95jMX4Q5jWYjKkSPEAmkndDUY', LVal.AsType<IPublicKey>.Key, 'I0 Source');

    AssertTrue(LDecoded[0].Values.TryGetValue('Authority', LVal), 'I0 missing "Authority"');
    AssertEquals('BWouvwpvenFxy7Sb2zmDQu1RuWLqFFbK9AbuY8aN96xn', LVal.AsType<IPublicKey>.Key, 'I0 Authority');

    AssertTrue(LDecoded[0].Values.TryGetValue('Amount', LVal), 'I0 missing "Amount"');
    AssertEquals(10000, LVal.AsType<UInt64>, 'I0 Amount (lamports)');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 1', LVal), 'I0 missing "Signer 1"');
    AssertEquals('238y27qL4hnoqByugWhKDA76T7mXHdfK6Qv7fyFqqPYm', LVal.AsType<IPublicKey>.Key, 'I0 Signer 1');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 2', LVal), 'I0 missing "Signer 2"');
    AssertEquals('AJk1YpH1g4A3M4XA1UWbxzMVi6jzSVYBuaRhAkJxK1vH', LVal.AsType<IPublicKey>.Key, 'I0 Signer 2');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 3', LVal), 'I0 missing "Signer 3"');
    AssertEquals('HFgCrTmWC8KGxxSLXN8Xm4FVQU73FtoupdZNDRqfMtV3', LVal.AsType<IPublicKey>.Key, 'I0 Signer 3');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeBurn;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(BurnMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    // assert
    AssertEquals(2, LDecoded.Count, 'Decoded instruction count');

    //
    // Instruction 0 - Token Program: Burn
    //
    AssertEquals('Burn', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('Token Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Account', LVal), 'I0 missing "Account"');
    AssertEquals('Gg12mmahG97PDACxKiBta7ch2kkqDkXUzjn5oAcbPZct', LVal.AsType<IPublicKey>.Key, 'I0 Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('Mint', LVal), 'I0 missing "Mint"');
    AssertEquals('J6WZY5nuYGJmfFtBGZaXgwZSRVuLWxNR6gd4d3XTHqTk', LVal.AsType<IPublicKey>.Key, 'I0 Mint');

    AssertTrue(LDecoded[0].Values.TryGetValue('Authority', LVal), 'I0 missing "Authority"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I0 Authority');

    AssertTrue(LDecoded[0].Values.TryGetValue('Amount', LVal), 'I0 missing "Amount"');
    AssertEquals(200, LVal.AsType<UInt64>, 'I0 Amount (lamports)');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeBurnMultisig;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(BurnMultisigMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    //
    // Instruction 1 - Token Program: Burn (Multisig)
    //
    AssertEquals('Burn', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('Token Program', LDecoded[1].ProgramName, 'I1 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertTrue(LDecoded[1].Values.TryGetValue('Account', LVal), 'I1 missing "Account"');
    AssertEquals('6ULjh7zKSsbiMqNzpCKMgYCUDFZ9Thxy59SGE48x22AF', LVal.AsType<IPublicKey>.Key, 'I1 Account');

    AssertTrue(LDecoded[1].Values.TryGetValue('Mint', LVal), 'I1 missing "Mint"');
    AssertEquals('HAbjCwXvJLRYPwsfLftT52iPYbHeGPyhPi3QCWiY2CTq', LVal.AsType<IPublicKey>.Key, 'I1 Mint');

    AssertTrue(LDecoded[1].Values.TryGetValue('Authority', LVal), 'I1 missing "Authority"');
    AssertEquals('7L1UA4SsaH3AonYX8mHXbLaLR3fiJY71S8zSZQ57WXv8', LVal.AsType<IPublicKey>.Key, 'I1 Authority');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 1', LVal), 'I1 missing "Signer 1"');
    AssertEquals('6yg3tZM1szHj752RDxQ1GxwvkzR3GyuvAcH498ew1t2T', LVal.AsType<IPublicKey>.Key, 'I1 Signer 1');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 2', LVal), 'I1 missing "Signer 2"');
    AssertEquals('88SzfLipgVTvi8hQwYfq21DgQFcABx6yAwgJH5shfqVZ', LVal.AsType<IPublicKey>.Key, 'I1 Signer 2');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 3', LVal), 'I1 missing "Signer 3"');
    AssertEquals('5Xcw7EQb6msgpVdGB8Hf8kpCqVyacTChgFBUphpuUeBo', LVal.AsType<IPublicKey>.Key, 'I1 Signer 3');

    AssertTrue(LDecoded[1].Values.TryGetValue('Amount', LVal), 'I1 missing "Amount"');
    AssertEquals(500000, LVal.AsType<UInt64>, 'I1 Amount');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeBurnCheckedMultisig;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(BurnCheckedMultisigMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    //
    // Instruction 1 - Token Program: Burn Checked (Multisig)
    //
    AssertEquals('Burn Checked', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('Token Program', LDecoded[1].ProgramName, 'I1 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertTrue(LDecoded[1].Values.TryGetValue('Account', LVal), 'I1 missing "Account"');
    AssertEquals('6ULjh7zKSsbiMqNzpCKMgYCUDFZ9Thxy59SGE48x22AF', LVal.AsType<IPublicKey>.Key, 'I1 Account');

    AssertTrue(LDecoded[1].Values.TryGetValue('Mint', LVal), 'I1 missing "Mint"');
    AssertEquals('HAbjCwXvJLRYPwsfLftT52iPYbHeGPyhPi3QCWiY2CTq', LVal.AsType<IPublicKey>.Key, 'I1 Mint');

    AssertTrue(LDecoded[1].Values.TryGetValue('Authority', LVal), 'I1 missing "Authority"');
    AssertEquals('7L1UA4SsaH3AonYX8mHXbLaLR3fiJY71S8zSZQ57WXv8', LVal.AsType<IPublicKey>.Key, 'I1 Authority');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 1', LVal), 'I1 missing "Signer 1"');
    AssertEquals('6yg3tZM1szHj752RDxQ1GxwvkzR3GyuvAcH498ew1t2T', LVal.AsType<IPublicKey>.Key, 'I1 Signer 1');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 2', LVal), 'I1 missing "Signer 2"');
    AssertEquals('88SzfLipgVTvi8hQwYfq21DgQFcABx6yAwgJH5shfqVZ', LVal.AsType<IPublicKey>.Key, 'I1 Signer 2');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 3', LVal), 'I1 missing "Signer 3"');
    AssertEquals('5Xcw7EQb6msgpVdGB8Hf8kpCqVyacTChgFBUphpuUeBo', LVal.AsType<IPublicKey>.Key, 'I1 Signer 3');

    AssertTrue(LDecoded[1].Values.TryGetValue('Amount', LVal), 'I1 missing "Amount"');
    AssertEquals(500000, LVal.AsType<UInt64>, 'I1 Amount');

    AssertTrue(LDecoded[1].Values.TryGetValue('Decimals', LVal), 'I1 missing "Decimals"');
    AssertEquals(10, LVal.AsType<Byte>, 'I1 Decimals');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeRevokeMultisig;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(RevokeMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    //
    // Instruction 1 - Token Program: Revoke (Multisig)
    //
    AssertEquals(3, LDecoded.Count, 'Decoded instruction count');
    AssertEquals('Revoke', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('Token Program', LDecoded[1].ProgramName, 'I1 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertTrue(LDecoded[1].Values.TryGetValue('Source', LVal), 'I1 missing "Source"');
    AssertEquals('6ULjh7zKSsbiMqNzpCKMgYCUDFZ9Thxy59SGE48x22AF', LVal.AsType<IPublicKey>.Key, 'I1 Source');

    AssertTrue(LDecoded[1].Values.TryGetValue('Authority', LVal), 'I1 missing "Authority"');
    AssertEquals('7L1UA4SsaH3AonYX8mHXbLaLR3fiJY71S8zSZQ57WXv8', LVal.AsType<IPublicKey>.Key, 'I1 Authority');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 1', LVal), 'I1 missing "Signer 1"');
    AssertEquals('6yg3tZM1szHj752RDxQ1GxwvkzR3GyuvAcH498ew1t2T', LVal.AsType<IPublicKey>.Key, 'I1 Signer 1');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 2', LVal), 'I1 missing "Signer 2"');
    AssertEquals('88SzfLipgVTvi8hQwYfq21DgQFcABx6yAwgJH5shfqVZ', LVal.AsType<IPublicKey>.Key, 'I1 Signer 2');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 3', LVal), 'I1 missing "Signer 3"');
    AssertEquals('5Xcw7EQb6msgpVdGB8Hf8kpCqVyacTChgFBUphpuUeBo', LVal.AsType<IPublicKey>.Key, 'I1 Signer 3');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestDecodeBurnCheckedAndCloseMultisig;
var
  LMsg     : IMessage;
  LDecoded : TList<IDecodedInstruction>;
  LVal     : TValue;
begin
  // arrange
  LMsg := TMessage.Deserialize(CloseAccountMultisigMessage);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LMsg);
  try
    //
    // Instruction 0 - Token Program: Burn Checked
    //
    AssertEquals('Burn Checked', LDecoded[0].InstructionName, 'I0 name');
    AssertEquals('Token Program', LDecoded[0].ProgramName, 'I0 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[0].PublicKey.Key, 'I0 program id');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');

    AssertTrue(LDecoded[0].Values.TryGetValue('Account', LVal), 'I0 missing "Account"');
    AssertEquals('6ULjh7zKSsbiMqNzpCKMgYCUDFZ9Thxy59SGE48x22AF', LVal.AsType<IPublicKey>.Key, 'I0 Account');

    AssertTrue(LDecoded[0].Values.TryGetValue('Mint', LVal), 'I0 missing "Mint"');
    AssertEquals('HAbjCwXvJLRYPwsfLftT52iPYbHeGPyhPi3QCWiY2CTq', LVal.AsType<IPublicKey>.Key, 'I0 Mint');

    AssertTrue(LDecoded[0].Values.TryGetValue('Authority', LVal), 'I0 missing "Authority"');
    AssertEquals('7L1UA4SsaH3AonYX8mHXbLaLR3fiJY71S8zSZQ57WXv8', LVal.AsType<IPublicKey>.Key, 'I0 Authority');

    AssertTrue(LDecoded[0].Values.TryGetValue('Amount', LVal), 'I0 missing "Amount"');
    AssertEquals(1999020000, LVal.AsType<UInt64>, 'I0 Amount');

    AssertTrue(LDecoded[0].Values.TryGetValue('Decimals', LVal), 'I0 missing "Decimals"');
    AssertEquals(10, LVal.AsType<Byte>, 'I0 Decimals');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 1', LVal), 'I0 missing "Signer 1"');
    AssertEquals('6yg3tZM1szHj752RDxQ1GxwvkzR3GyuvAcH498ew1t2T', LVal.AsType<IPublicKey>.Key, 'I0 Signer 1');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 2', LVal), 'I0 missing "Signer 2"');
    AssertEquals('88SzfLipgVTvi8hQwYfq21DgQFcABx6yAwgJH5shfqVZ', LVal.AsType<IPublicKey>.Key, 'I0 Signer 2');

    AssertTrue(LDecoded[0].Values.TryGetValue('Signer 3', LVal), 'I0 missing "Signer 3"');
    AssertEquals('5Xcw7EQb6msgpVdGB8Hf8kpCqVyacTChgFBUphpuUeBo', LVal.AsType<IPublicKey>.Key, 'I0 Signer 3');

    //
    // Instruction 1 - Token Program: Close Account
    //
    AssertEquals('Close Account', LDecoded[1].InstructionName, 'I1 name');
    AssertEquals('Token Program', LDecoded[1].ProgramName, 'I1 program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LDecoded[1].PublicKey.Key, 'I1 program id');
    AssertEquals(0, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    AssertTrue(LDecoded[1].Values.TryGetValue('Account', LVal), 'I1 missing "Account"');
    AssertEquals('6ULjh7zKSsbiMqNzpCKMgYCUDFZ9Thxy59SGE48x22AF', LVal.AsType<IPublicKey>.Key, 'I1 Account');

    AssertTrue(LDecoded[1].Values.TryGetValue('Destination', LVal), 'I1 missing "Destination"');
    AssertEquals('5omQJtDUHA3gMFdHEQg1zZSvcBUVzey5WaKWYRmqF1Vj', LVal.AsType<IPublicKey>.Key, 'I1 Destination');

    AssertTrue(LDecoded[1].Values.TryGetValue('Authority', LVal), 'I1 missing "Authority"');
    AssertEquals('7L1UA4SsaH3AonYX8mHXbLaLR3fiJY71S8zSZQ57WXv8', LVal.AsType<IPublicKey>.Key, 'I1 Authority');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 1', LVal), 'I1 missing "Signer 1"');
    AssertEquals('6yg3tZM1szHj752RDxQ1GxwvkzR3GyuvAcH498ew1t2T', LVal.AsType<IPublicKey>.Key, 'I1 Signer 1');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 2', LVal), 'I1 missing "Signer 2"');
    AssertEquals('88SzfLipgVTvi8hQwYfq21DgQFcABx6yAwgJH5shfqVZ', LVal.AsType<IPublicKey>.Key, 'I1 Signer 2');

    AssertTrue(LDecoded[1].Values.TryGetValue('Signer 3', LVal), 'I1 missing "Signer 3"');
    AssertEquals('5Xcw7EQb6msgpVdGB8Hf8kpCqVyacTChgFBUphpuUeBo', LVal.AsType<IPublicKey>.Key, 'I1 Signer 3');
  finally
    LDecoded.Free;
  end;
end;

procedure TTokenProgramTests.TestMultiSignatureAccountDeserialization;
var
  LAccount : IMultiSignatureAccount;
begin
  // arrange
  LAccount := TMultiSignatureAccount.Deserialize(TEncoders.Base64.DecodeData(MultiSignatureAccountBase64Data));

  // assert
  AssertEquals(3, LAccount.MinimumSigners, 'MinimumSigners');
  AssertEquals(5, LAccount.NumberSigners, 'NumberSigners');
  AssertTrue(LAccount.IsInitialized, 'IsInitialized');
  AssertEquals(5, LAccount.Signers.Count, 'Signers count');
  AssertEquals('6yg3tZM1szHj752RDxQ1GxwvkzR3GyuvAcH498ew1t2T', LAccount.Signers[0].Key, 'Signer 1');
  AssertEquals('88SzfLipgVTvi8hQwYfq21DgQFcABx6yAwgJH5shfqVZ', LAccount.Signers[1].Key, 'Signer 2');
  AssertEquals('5Xcw7EQb6msgpVdGB8Hf8kpCqVyacTChgFBUphpuUeBo', LAccount.Signers[2].Key, 'Signer 3');
  AssertEquals('CkuRf85gy9Q2733Hi5bFFuznpWjn19XzhJQQyz8LTaMi', LAccount.Signers[3].Key, 'Signer 4');
  AssertEquals('GmYy7Gkhkz4DWsA4RpCZoLS8UXpv8iZzTAESziYgRBEq', LAccount.Signers[4].Key, 'Signer 5');
end;

procedure TTokenProgramTests.TestTokenAccountDeserialization;
var
  LAcc : ITokenAccount;
begin
  // arrange
  LAcc := TTokenAccount.Deserialize(TEncoders.Base64.DecodeData(TokenAccountBase64Data));

  // assert
  AssertEquals(0, LAcc.Amount, 'Amount');
  AssertEquals(0, LAcc.DelegatedAmount, 'DelegatedAmount');
  AssertNull(LAcc.CloseAuthority, 'CloseAuthority');
  AssertNull(LAcc.Delegate, 'Delegate');
  AssertFalse(LAcc.IsNative.HasValue, 'IsNative');
  AssertEquals('EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v', LAcc.Mint.Key, 'Mint');
  AssertEquals('EonUxoMY3tjMnnES8yeKu5sx8LocsEM8mb4Y38cMJQuc', LAcc.Owner.Key, 'Owner');
  AssertEquals(Ord(TTokenAccountState.Initialized), Ord(LAcc.State), 'State');
end;

procedure TTokenProgramTests.TestTokenMintAccountDeserialization;
var
  LMint : ITokenMint;
begin
  // arrange
  LMint := TTokenMint.Deserialize(TEncoders.Base64.DecodeData(TokenMintAccountBase64Data));

  // assert
  AssertEquals(6, LMint.Decimals, 'Decimals');
  AssertEquals(4785000018865782, LMint.Supply, 'Supply');
  AssertTrue(LMint.IsInitialized, 'IsInitialized');
  AssertEquals('3sNBr7kMccME5D55xNgsmYpZnzPgP2g12CixAajXypn6', LMint.FreezeAuthority.Key, 'FreezeAuthority');
  AssertEquals('2wmVCSfPxGPjrnMMn7rchp4uaeoTqN39mXFC2zhPdri9', LMint.MintAuthority.Key, 'MintAuthority');
end;

procedure TTokenProgramTests.TestDecodeInitAccount3;
var
  LJson : string;
  LTxMeta       : TTransactionMetaInfo;
  LDecoded      : TList<IDecodedInstruction>;
  LInner        : IDecodedInstruction;
  LVal          : TValue;
begin
  // arrange
  LJson := LoadTestData('Token/DecodeInitAccount3.json');
  LTxMeta := TTestUtils.Deserialize<TTransactionMetaInfo>(LJson);

  // act
  LDecoded := TInstructionDecoder.DecodeInstructions(LTxMeta);
  try
    // assert
    AssertEquals(2, LDecoded.Count, 'Decoded instruction count');
    AssertEquals(0, LDecoded[0].InnerInstructions.Count, 'I0 inner count');
    AssertEquals(9, LDecoded[1].InnerInstructions.Count, 'I1 inner count');

    LInner := LDecoded[1].InnerInstructions[6];
    AssertEquals(3, LInner.Values.Count, 'Inner[6] values count');

    AssertEquals('Initialize Account 3', LInner.InstructionName, 'Inner[6] name');
    AssertEquals('Token Program', LInner.ProgramName, 'Inner[6] program');
    AssertEquals('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', LInner.PublicKey.Key, 'Inner[6] program id');

    AssertTrue(LInner.Values.TryGetValue('Account', LVal), 'Inner[6] missing "Account"');
    AssertEquals('GDZzNq3B69BdUAHEijjY5QZW2VKoHKYmPZFJi64uTWbK', LVal.AsType<IPublicKey>.Key, 'Inner[6] Account');

    AssertTrue(LInner.Values.TryGetValue('Mint', LVal), 'Inner[6] missing "Mint"');
    AssertEquals('FkfMaBkeqt3GAQLoKJrMbQKWpynL51o3JgEbK1jHJ6Qg', LVal.AsType<IPublicKey>.Key, 'Inner[6] Mint');

    AssertTrue(LInner.Values.TryGetValue('Authority', LVal), 'Inner[6] missing "Authority"');
    AssertEquals('C4Pxqsppptwq766W3nmfuWxvENQ9xmVwVkdYHqzUGKo9', LVal.AsType<IPublicKey>.Key, 'Inner[6] Authority');
  finally
    LTxMeta.Free;
    LDecoded.Free;
  end;
end;

initialization
{$IFDEF FPC}
  RegisterTest(TTokenProgramTests);
{$ELSE}
  RegisterTest(TTokenProgramTests.Suite);
{$ENDIF}

end.

