{$rangeChecks on}
{*
  中国象棋
  * 运行于Terminal下
  * 操作方式兼容vi
  * 需要安装象棋字形: https://www.babelstone.co.uk/Fonts/Xiangqi.html
  * 建议使用kitty - 一个基于GPU的快速, 多功能终端模拟器(https://sw.kovidgoyal.net/kitty/)来运行。
*}
program chess;
uses crt, dos, SysUtils;
{*
 棋盘
 棋盘是一个9x10的方格，横线为线，纵线为路，共有10线9路
 线路交叉点为棋子点位
*}
type
    TRoad = 1..9;
    TRank = 1..10;

{* 绘制棋盘
   绘制棋盘需要绘制棋子的点位，即路和线的交叉点
 *}
const
    space = 3;
    point = '+';

{*
  计算棋盘边距
*}
function Margin : byte;
begin
    Margin := ( screenwidth - space * high(TRoad) + 1) div 2;
end;

procedure DrawBoard;
var
    i: TRank;
    j: TRoad;
begin
    clrscr;
    for i := low(TRank) to high(TRank) do
    begin
        gotoXY(Margin - space, i);
        writeln(11 - i:2);
        for j := low(TRoad) to high(TRoad) do
        begin
            gotoXY(j * space - space + Margin, i);
            writeln(point);
        end;
    end;
    for j := low(TRoad) to high(TRoad) do
    begin
        gotoXY(j * space - space + Margin, 11);
        writeln(10 - j);
    end;
end;

{*
 棋子
 棋子分为两方: 红子、黑子
 棋子的名称有：帅、士、相、马、车、炮、兵
*}
type 
    TSide = (Red, Black);
    TName = (General, Advisor, Elephant, Horse, Chariot, Cannon, Soldier);

{*
 棋面
 棋面按红方和黑方，及其名字进行确定
*}
const
    faces: Array [TSide, TName] of String = (('🩠', '🩡', '🩢', '🩣', '🩤', '🩥', '🩦'), ('🩧', '🩨', '🩩', '🩪', '🩫', '🩬', '🩭'));

{*
  棋子
  棋子根据红黑方, 名字，以及它在棋盘上的位置互相区别
  每个棋子有一个selected值，表示它是否属于选中状态
  每个棋子还有一个blink属性，表示它是否属于闪烁状态
  每个棋子包括一个next指针，这样可以把所有棋子连起来
*}
type
    TPiece = Record
        side: TSide;
        name: TName;
        rank: TRank;
        road: TRoad;
        selected: Boolean;
        blink: Boolean;
        next: ^TPiece;
    end;

{ 显示棋子 }
procedure ShowPiece(p: TPiece);
begin
    gotoXY(p.road * space - space + Margin, p.rank);
    writeln(faces[p.side][p.name]);
end;

{* 棋局
   一局棋就是一组棋子
   在行棋的过程中，棋子会由于被对方吃掉而减少
*}
type
    TRound = ^TPiece;
var
    round: TRound = nil;

{ 显示某个位置的棋子 }
procedure ShowPieceXY(rank: TRank; road: TRoad);
var
    p: ^TPiece = nil;
begin
    p := round;
    while  p <> nil do
    begin
        if (p^.rank = rank) and (p^.road = road) then
        begin
            gotoXY(road * space - space + Margin, rank);
            writeln(faces[p^.side][p^.name]);
            break;
        end;
        p := p^.next;
    end;
    if p = nil then
    begin
        gotoXY(road * space - space + Margin, rank);
        writeln(point);
    end;
end;

{ 增加一个棋子 }
procedure AddPiece(side: TSide; name: TName; rank: TRank; road: TRoad);
var
    p: ^TPiece;
begin
    new(p);
    p^.side := side;
    p^.name := name;
    p^.rank := rank;
    p^.road := road;
    p^.selected := false;
    p^.blink := false;
    p^.next := round;
    round := p;
end;

{ 删除一个棋子 }
procedure DelPiece(p: TRound);
var
    q: ^TPiece;
begin
    if p = round then
    begin
        round := round^.next;
        dispose(p);
    end
    else
    begin
        q := round;
        while q^.next <> p do
            q := q^.next;
        q^.next := q^.next^.next;
        dispose(p);
    end;
end;

procedure ClearPiece;
begin
    while round <> nil do
        DelPiece(round);
end;

{ 移动棋子 }
procedure MovePiece(p: TRound; i: TRank; j: TRoad);
var
    q: TPiece;
begin
    q := p^;
    p^.rank := i;
    p^.road := j;
    ShowPieceXY(q.rank, q.road);
end;

{* 摆棋  
  摆棋的过程就是把一局棋所需要的32颗棋子依次摆放到各自固定的位置上，先后顺序无关
*}
procedure ResetRound;
var
    p: ^TPiece;
begin
    if round <> nil then
        ClearPiece;
    AddPiece(Red, Chariot, 1, 1);
    AddPiece(Red, Horse, 1, 2);
    AddPiece(Red, Elephant, 1, 3);
    AddPiece(Red, Advisor, 1, 4);
    AddPiece(Red, General, 1, 5);
    AddPiece(Red, Advisor, 1, 6);
    AddPiece(Red, Elephant, 1, 7);
    AddPiece(Red, Horse, 1, 8);
    AddPiece(Red, Chariot, 1, 9);
    AddPiece(Red, Cannon, 3, 2);
    AddPiece(Red, Cannon, 3, 8);
    AddPiece(Red, Soldier, 4, 1);
    AddPiece(Red, Soldier, 4, 3);
    AddPiece(Red, Soldier, 4, 5);
    AddPiece(Red, Soldier, 4, 7);
    AddPiece(Red, Soldier, 4, 9);
    AddPiece(Black, Chariot, 10, 1);
    AddPiece(Black, Horse, 10, 2);
    AddPiece(Black, Elephant, 10, 3);
    AddPiece(Black, Advisor, 10, 4);
    AddPiece(Black, General, 10, 5);
    AddPiece(Black, Advisor, 10, 6);
    AddPiece(Black, Elephant, 10, 7);
    AddPiece(Black, Horse, 10, 8);
    AddPiece(Black, Chariot, 10, 9);
    AddPiece(Black, Cannon, 8, 2);
    AddPiece(Black, Cannon, 8, 8);
    AddPiece(Black, Soldier, 7, 1);
    AddPiece(Black, Soldier, 7, 3);
    AddPiece(Black, Soldier, 7, 5);
    AddPiece(Black, Soldier, 7, 7);
    AddPiece(Black, Soldier, 7, 9);
    p := round;
    while p <> nil do
    begin
        ShowPiece(p^);
        p := p^.next;
    end;
end;

{ 当前行棋方，以及选择移动的棋子 }
var
    curside: TSide = Red;
    curpiece: ^TPiece = nil;

{ 改变行棋方 }
procedure ChangeSide;
begin
    if curside = Red then
        curside := Black
    else
        curside := Red;
end;

{* 闪烁棋子
  闪烁棋子的原理是通过重复的调用，根据时间来刷新blink为true的棋子的显示状态。
 *}
procedure BlinkPiece;
    procedure Blink(enable: Boolean);
    var
        p: ^TPiece;
    begin
        p := round;
        while p <> nil do
        begin
            if p^.blink then
            begin
                gotoXY(p^.road * space - space + Margin, p^.rank);
                if enable then
                    writeln(point)
                else
                    writeln(faces[p^.side][p^.name]);
            end;
            p := p^.next;
        end;
    end; { Blink }
var
    sec, sec100, min, hour: word;
begin
    getTime(hour, min, sec, sec100);
    Blink(sec100 > 50);
end;

{*行棋
  行棋就是移动一颗棋子到另一个位置，如果该位置有对方的棋子，则对方的棋子就被吃掉
  如果对方的General棋子被吃掉，则行棋方赢棋
  名字不同的棋子，其行棋规则也不相同，包括：
  车: 
    1. 下一个位置和当前位置相隔若干条线，或者若干条路
    2. 下一个位置和当前位置之间不能有其它棋子
  马: 
    1. 下一个位置和当前位置相隔一条线、两条路，或者一条路、两条线
    2. 下一个位置和当前位置之间相隔一的相邻位置不能有其它棋子
  象/相: 
    1. 下一个位置和当前位置相隔两条线、两条路
    2. 相隔一条线、一条路的位置不能有棋子
  士: 
    1. 下一个位置和当前位置相隔一条线、一条路
    2. 下一个位置不能超出九宫格的范围
  将: 
    1. 下一个位置和当前位置相隔一条线，或者一条路
    2. 同士2
  炮: 
    1. 同车1
    2. 下一个位置和当前位置中间有且只能有一个棋子
  兵: 
    1. 同将1
    2. 当前位置的线小于6时，下一个位置的线必须大于当前位置的线
    3. 当前位置的线大于5时，下一个位置的线不得小于当前位置的线
*}
begin
    DrawBoard;
    ResetRound;
    gotoXY(1, ScreenHeight - 1);
end.
