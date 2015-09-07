Introducing MA*:  Maker Asset (Platform|Registry|Interface|Controllers)


Maker's ultimate goal is the deployment and widespread adoption of the Dai stablecoin and credit system.

The Maker contract system interacts with multiple assets on the Ethereum blockchain.

To do this, it wraps them in contracts which make them easier to manipulate programmatically.

At the moment, this only includes ETH and MKR, but it can be done for any asset which allows one of our system addresses to have
a balance. 

Now, we are exposing a subset of our contract API to the public to allow anyone to take advantage of our
contract infrastructure. In my opinion, we have by far the most elegant asset manipulation API, as well
as the only asset platform which allows us to add features and optimizations without breaking user
contracts or static UIs.

All contracts in the registry are `MakerAsset`s, which implement the transaction buffer
model ("withdraw/charge" model) as well as the usual transfer model. The transaction buffer model makes
it easer to reason about correctness using helper modifiers, lets you write asset "flow" contracts in a
way that are automatically easy to compose, and generally feels less clunky for contracts of all levels
of complexity.

    contract MakerAsset {
        function supply() constant returns (uint current_supply);
        function balances( address who ) constant returns (uint amount);

        function transfer( address to, uint amount ) returns (bool success);

        function buffered_balances( address who ) constant returns (uint amount);

        function withdraw( uint amount ) returns (bool success);
        function withdraw_and_call( uint amount, address target, bytes calldata) returns (bool success);
        function charge( uint amount ) returns (bool success);
    }


Using assets in the Maker ecosystem is easy, in part because of the `MakerUser` mixin.
A mixin is what I call a contract with only internal functions - it is not an abstract contract (an interface),
but the compiler will only emit anything if you use one of the internal functions in a derived contract. It is like a package of helper functions.

Follow the installation guide until you are able to compile/run these .sol/.js files, respectively.

`example.sol`:
    
    import 'maker/user.sol';

    contract Example is MakerUser {
    }

`example.js`:

    var maker = require("maker")(web3);


Assets are stored in the Maker Asset Registry. Accessing the registry is easy:

`example.sol`:
    
    import 'maker/user.sol';

    contract Example is MakerUser {
        function example() {
            MakerAssetRegistry reg = MAR(); // == asset_registry()
        }
    }


`example.js`

    var maker = require("maker")(web3);
    var registry = maker.MAR();


Things to note:
    * Everything inside MakerUser is an internal function. This means it isn't exposed
      as an entrypoint, and it also isn't compiled into the contract unless you actually
      use it.
    * NEVER save address references. The only fixed addresses in the Maker system
      are already hard-coded in the `MakerUser` mixin. You should always be using helper functions
      unless you really know what you are doing. Efficiency is a long-term goal and generally
      each new release of `MakerUser` (and every other component of Maker) will add less and
      less overhead. However, for now we are prioritizing correctness and code simplicity over
      efficiency. If you plan on deploying a very long-running contract soon and want to learn how to
      safely cut corners, you should contact the Maker core dev team for help.


Once you have the registry, you can get assets by symbol. You can also just use a built-in helper.

`example.sol`:
    
    import 'maker/user.sol';

    contract Example is MakerUser {
        function example() {
            MakerAssetRegistry reg = MAR(); // == asset_registry()
            MakerAsset ETH = reg.get_asset("ETH") // from (local to trx!) registry reference
            MakerAsset MKR = maker_asset("MKR") // from helper
        }
    }


`example.js`

    var maker = require("maker")(web3);
    var reg = maker.MAR();
    var ETH = reg.get_asset("ETH");
    var MKR = maker.maker_asset


Now we can finally learn to use the contract interface. The `.sol` and `.js` examples are going to diverge, because
the intended usage is different for contracts and for keys.

Let's start with the contract example. I'll rewrite the example to be a basic
OTC sell contract, which must be created by someone deliberately spending ETH,
then filled by someone with MKR who wants to trade.


`example.sol`:
    
    import 'maker/user.sol';

    contract SimpleOTC is MakerUser {
        address creator;
        function SimpleOTC() {
            creator = msg.sender;
            var ETH = maker_asset("ETH");
            if( ! ETH.charge(1000) ) { // whoever instantiated this didn't have enough ETH
                suicide(msg.sender);
            }
            // This address now has 1000 ETH
        }
        function fill() {
            var MKR = maker_asset("MKR");
            var ETH = maker_asset("ETH");
            if( MKR.charge(500) ) {
                MKR.transfer(creator, 500);
                ETH.withdraw(1000);
                suicide(msg.sender);
            }
        }
    }

