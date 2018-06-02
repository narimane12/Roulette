pragma solidity ^0.4.17;
contract Roulette {
//déclaration de variable
    uint public lastRoundTimestamp;    //dernier tour
    uint public nextRoundTimestamp;    //prochain tour.
    string public message = "Premier Message";
    address public _creator;           //adresse du créateur du contrat
    uint public _interval;             //intervalle entre deux tours

    enum BetType { Single, Odd, Even }

    struct Bet {
        BetType betType;     //le type du pari
        address player;     //adresse du joueur ayant fait le pari
        uint number;       //numéro sur lequel a misé le joueur
        uint value;       //la mise
    }

    Bet[] public bets;
//fonction permettant de connaître le nombre de paris en cours, et la valeur totale des paris
    function getBetsCountAndValue() public constant returns(uint, uint,string) {
        uint value = 0;
        for (uint i = 0; i < bets.length; i++) {
            value += bets[i].value;
        }
        return (bets.length, value,message);
    }

    event Finished(uint number, uint nextRoundTimestamp);
//la déclaration de la fonction, transactionMustContainEther qui est un modifier
//cette fonction ajoute une instruction au début des fonctions sur lesquels il est utilisé
    modifier transactionMustContainEther() {
        require(msg.value != 0);
        _;                                //c’est à cet endroit que sera exécuté le code de la fonction modifiée.
    }


    modifier bankMustBeAbleToPayForBetType(BetType betType) {
        uint necessaryBalance = 0;
        for (uint i = 0; i < bets.length; i++) {
            necessaryBalance += getPayoutForType(bets[i].betType) * bets[i].value;
        }
        necessaryBalance += getPayoutForType(betType) * msg.value;
        require(necessaryBalance <= this.balance);
        _;
    }
//La fonction getPayoutForType nous permet ici de récupérer le coefficient multiplicateur de la mise
//si le pari est gagnant (×35 pour un numéro simple, ×2 pour les pairs/impairs)
    function getPayoutForType(BetType betType) constant returns(uint) {
        if (betType == BetType.Single) return 35;
        if (betType == BetType.Even || betType == BetType.Odd) return 2;
        return 0;
    }
// constructeur
    function Roulette() payable {
        _interval =10;
        _creator = msg.sender;
        nextRoundTimestamp = now + _interval;
    }
//La fonction betSingle permet de miser sur un numéro.
    function betSingle(uint number) public  payable transactionMustContainEther() bankMustBeAbleToPayForBetType(BetType.Single) {

            require(number <= 36);
            bets.push(Bet({
            betType: BetType.Single,
            player: msg.sender,
            number: number,
            value: msg.value
        }));
    }
//La fonction betEven permet de miser sur un numéro pair
    function betEven() public payable transactionMustContainEther() bankMustBeAbleToPayForBetType(BetType.Even) {
        bets.push(Bet({
            betType: BetType.Even,
            player: msg.sender,
            number: 0,
            value: msg.value
        }));
    }
//La fonction betOdd permet de miser sur un numéro impair
    function betOdd() public payable transactionMustContainEther() bankMustBeAbleToPayForBetType(BetType.Odd) {
        bets.push(Bet({
            betType: BetType.Odd,
            player: msg.sender,
            number: 0,
            value: msg.value
        }));
    }
// la fonction launche permet de lancer la roulette
    function launch() public payable {

        require(now >= nextRoundTimestamp);
        uint number = uint(block.blockhash(block.number - 1)) % 37; //On tire ensuite un nombre « aléatoire »

        for (uint i = 0; i < bets.length; i++) {   // parcourir chaque pari, et vérifier s’il est gagnant ou non en fonction de son type
            bool won = false;
            uint payout = 0;
            if (bets[i].betType == BetType.Single) {
                if (bets[i].number == number) {
                    won = true;
                }
            } else if (bets[i].betType == BetType.Even) {
                if (number > 0 && number % 2 == 0) {
                    won = true;
                }
            } else if (bets[i].betType == BetType.Odd) {
                if (number > 0 && number % 2 == 1) {
                    won = true;
                }
            }
            if (won) {   //on émet une transaction grâce à la méthode send applicable aux variables de type address
                bets[i].player.send(bets[i].value * getPayoutForType(bets[i].betType));
            }
        }

        uint thisRoundTimestamp = nextRoundTimestamp;
        nextRoundTimestamp = thisRoundTimestamp + _interval; //on définit la date du prochain tour
        lastRoundTimestamp = thisRoundTimestamp;

        bets.length = 0;             //on vide le tableau des paris en cours

        Finished(number, nextRoundTimestamp);
    }





    function kill() public {
      require(msg.sender == _creator);
      suicide(_creator);
    }

}
