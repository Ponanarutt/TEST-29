// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "contracts/CommitReveal.sol";

contract RPS is CommitReveal{
    struct Player {
        uint choice; // 0 - Rock, 1 - Water , 2 - Air, 3 - Paper, 4 - Sponge, 5 - Scissors, 6 - Fire, 7 - undefined
        address addr;
        uint timestamp;
        bool input;
    }

    uint public numPlayer = 0;
    uint public reward = 0;

    mapping (uint => Player) public player;
    uint public numInput = 0 ;
    uint public Limiter = 1 hours ;
    unit public peipai = 0 ;

    mapping (address => uint) public addplayer ; // ระบุตัวเจ้าของ

   // SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./CommitReveal.sol";

contract RPS is CommitReveal{
    struct Player {
        uint choice; // 0 -> 6 
        address addr;
        uint timestamp;
        bool input;
    }

    uint public numPlayer = 0;
    uint public reward = 0;

    mapping (uint => Player) public player;
    uint public numInput = 0 ;
    uint public Limiter = 1 minutes ; // test timeout
    uint public peipai = 0 ;

    mapping (address => uint) public addplay ; // ระบุตัวเจ้าของ

    function addPlayer() public payable {
        require(numPlayer < 2); // ห้ามเกิน 2 
        require(msg.value == 1 ether); 
        require(player[0].addr != msg.sender);

        reward += msg.value;
        //สร้างตัวละคร

        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = 7;
        player[numPlayer].timestamp = block.timestamp ;
        player[numPlayer].input = false ;
        addplay[msg.sender] = numPlayer;
        numPlayer++;
    }

    function input(uint choice) public  {
        
        uint idx = addplay[msg.sender];

        require(numPlayer == 2);
        require(msg.sender == player[idx].addr);
        require(peipai == 0);
        require(choice < 7 && choice >= 0);
        if (player[idx].input == false){
            numInput++ ;
        }
        player[idx].timestamp = block.timestamp;
        player[idx].input = true ;

        bytes32  hashData = getHash(bytes32(choice));
        commit(hashData);
        
    }

    function clear() private  {
        
        // รีเซ็ทข้อมูล player 
        address account0 = player[0].addr;
        address account1 = player[1].addr;

        delete addplay[account0];
        delete addplay[account1];

        delete player[0];
        delete player[1];

        // เซ็ทข้อมูลกลับ
        numPlayer = 0 ;
        numInput = 0 ;
        reward = 0 ;
        peipai = 0 ;
    }

    function _checkWinnerAndPay() private {

        uint p0Choice = player[0].choice;
        uint p1Choice = player[1].choice;

        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        
        //เสมอทำก่อนจะได้ไม่ต้องเสียเวลาคำณวน
        if (p0Choice == p1Choice){
            account0.transfer(reward/2);
            account1.transfer(reward/2);
        }

        //p0 เเพ้ ตรวจการเเพ้ 3 อันดับก่อน
        else if(p0Choice-1 % 7 == p1Choice || p0Choice-2 % 7 == p1Choice || p0Choice-3 % 7 == p1Choice){
            account1.transfer(reward);
        }

        //p0 ชนะ
        else{
            account0.transfer(reward);
        }
    }

    function revealing(uint choice) public {
        uint idx = addplay[msg.sender];
        reveal(bytes32(choice));
        
        require(numInput == 2);
        
        peipai++;
        player[idx].choice = choice ;
        if(peipai == 2){
            _checkWinnerAndPay();
        }

    }

    function draw() public {

        uint idx = addplay[msg.sender];

        require(numPlayer == 1 || numPlayer == 2);
        require(msg.sender == player[idx].addr);
        require(block.timestamp - player[idx].timestamp > Limiter);
        require(player[1].addr  == msg.sender || player[0].addr == msg.sender );
        

        if (numPlayer == 2 && numInput == 2 && peipai < 2){
            require(commits[msg.sender].revealed == true);
        }

        else if (numPlayer == 1){ idx = 0; }

        else if (numPlayer == 2 && numInput < 2){
            require(player[idx].input == true);
        }
        
        address payable wallet = payable(player[idx].addr);
        wallet.transfer(reward);

        clear();
    }

    
}
