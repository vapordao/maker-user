import 'dappsys/math/math.sol';

// An interface contract with the ability to upgrade. This is
// to be replaced with the Maker kernel, which will also implement
// the latest version of the interface and then do all upgrades to itself
// (see dynamic contracts)
// Use the MakerUser utility mixin to correctly interact with "the" maker
// contract. You probably don't want to ever refer to `Maker` directly.
contract Maker {
    function get(bytes32 key) constant returns (bytes32);
    function latest_version() returns (Maker latest_version);
}

contract MakerAssetMathMixin is DSFixedPointMathMixin(10**18) {}

contract MakerAsset {
    function balances( address who ) constant returns (uint amount);
    function supply() constant returns (uint current_supply);
    function transfer( address to, uint amount ) returns (bool success);


    function withdraw( uint amount ) returns (bool success);
    function withdraw_and_call( uint amount
                              , address target
                              , bytes calldata)
             returns (bool success);
    function charge( uint amount ) returns (bool success);
    function buffered_balance() constant returns (uint amount);
    function buffered_balances( address who ) constant returns (uint amount);
}

contract MakerAssetRegistry {
    function get_asset(bytes32 symbol) returns (MakerAsset);
    function set_asset( bytes32 symbol, MakerAsset a ) returns (bool);
    function get_symbol( MakerAsset i) returns (bytes32 symbol);
}


