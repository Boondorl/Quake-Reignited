/************************************************************************************
***  Copyright (C) 1996-1997  Id Software, Inc.
***  Modifications Copyright (C) 2022  Boondorl
***
***  This program is free software: you can redistribute it and/or modify
***  it under the terms of the GNU General Public License as published by
***  the Free Software Foundation, either version 3 of the License, or
***  (at your option) any later version.
***
***  This program is distributed in the hope that it will be useful,
***  but WITHOUT ANY WARRANTY; without even the implied warranty of
***  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
***  GNU General Public License for more details.
***
***  You should have received a copy of the GNU General Public License
***  along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.html.
***
***  See file 'LICENSE' for details.
************************************************************************************/
/*
==============================================================================

DOG (Rottweiler)

==============================================================================
*/
$cd id1/models/dog
$origin 0 0 24
$base base
$skin skin

$frame attack1 attack2 attack3 attack4 attack5 attack6 attack7 attack8

$frame death1 death2 death3 death4 death5 death6 death7 death8 death9

$frame deathb1 deathb2 deathb3 deathb4 deathb5 deathb6 deathb7 deathb8
$frame deathb9

$frame pain1 pain2 pain3 pain4 pain5 pain6

$frame painb1 painb2 painb3 painb4 painb5 painb6 painb7 painb8 painb9 painb10
$frame painb11 painb12 painb13 painb14 painb15 painb16

$frame run1 run2 run3 run4 run5 run6 run7 run8 run9 run10 run11 run12

$frame leap1 leap2 leap3 leap4 leap5 leap6 leap7 leap8 leap9

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8 stand9

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8


void() dog_leap1;
void() dog_run1;

/*
================
dog_bite

================
*/
void() dog_bite =
{
	if (!self.enemy)
		return;

	ai_charge(10);

	MeleeAttack(20, 80, 50);
};

void()	Dog_JumpTouch =
{
	if (!other.takedamage && !(self.flags & FL_ONGROUND))
		return;
		
	self.touch = SUB_Null;
	
	if (self.health <= 0)
		return;
		
	if (other.takedamage)
	{
		if (vlen(self.velocity) >= 144)
			T_Damage (other, self, self, 20, 50, FALSE);	
	}

	self.special_time = time + 1;
	self.think = dog_run1;
	self.nextthink = time + 0.1;
};


void() dog_stand1	=[	$stand1,	dog_stand2	] {ai_stand();};
void() dog_stand2	=[	$stand2,	dog_stand3	] {ai_stand();};
void() dog_stand3	=[	$stand3,	dog_stand4	] {ai_stand();};
void() dog_stand4	=[	$stand4,	dog_stand5	] {ai_stand();};
void() dog_stand5	=[	$stand5,	dog_stand6	] {ai_stand();};
void() dog_stand6	=[	$stand6,	dog_stand7	] {ai_stand();};
void() dog_stand7	=[	$stand7,	dog_stand8	] {ai_stand();};
void() dog_stand8	=[	$stand8,	dog_stand9	] {ai_stand();};
void() dog_stand9	=[	$stand9,	dog_stand1	] {ai_stand();};

void() dog_walk1	=[	$walk1 ,	dog_walk2	]
{
	IdleSound("dog/idle.wav", 0.2);
	ai_walk(8);
};
void() dog_walk2	=[	$walk2 ,	dog_walk3	] {ai_walk(8);};
void() dog_walk3	=[	$walk3 ,	dog_walk4	] {ai_walk(8);};
void() dog_walk4	=[	$walk4 ,	dog_walk5	] {ai_walk(8);};
void() dog_walk5	=[	$walk5 ,	dog_walk6	] {ai_walk(8);};
void() dog_walk6	=[	$walk6 ,	dog_walk7	] {ai_walk(8);};
void() dog_walk7	=[	$walk7 ,	dog_walk8	] {ai_walk(8);};
void() dog_walk8	=[	$walk8 ,	dog_walk1	] {ai_walk(8);};

void() dog_run1		=[	$run1  ,	dog_run2	]
{
	IdleSound("dog/idle.wav", 0.2);
	ai_run(18);
};
void() dog_run2		=[	$run2  ,	dog_run3	] {ai_run(34);};
void() dog_run3		=[	$run3  ,	dog_run4	] {ai_run(34);};
void() dog_run4		=[	$run4  ,	dog_run5	] {ai_run(22);};
void() dog_run5		=[	$run5  ,	dog_run6	] {ai_run(69);};
void() dog_run6		=[	$run6  ,	dog_run7	] {ai_run(34);};
void() dog_run7		=[	$run7  ,	dog_run8	] {ai_run(18);};
void() dog_run8		=[	$run8  ,	dog_run9	] {ai_run(34);};
void() dog_run9		=[	$run9  ,	dog_run10	] {ai_run(34);};
void() dog_run10	=[	$run10  ,	dog_run11	] {ai_run(22);};
void() dog_run11	=[	$run11  ,	dog_run12	] {ai_run(69);};
void() dog_run12	=[	$run12  ,	dog_run1	] {ai_run(34);};

void() dog_atta1	=[	$attack1,	dog_atta2	] {ai_charge(10);};
void() dog_atta2	=[	$attack2,	dog_atta3	] {ai_charge(10);};
void() dog_atta3	=[	$attack3,	dog_atta4	] {ai_charge(10);};
void() dog_atta4	=[	$attack4,	dog_atta5	]
{
	sound (self, CHAN_VOICE, "dog/dattack1.wav", 1, ATTN_NORM);
	dog_bite();
};
void() dog_atta5	=[	$attack5,	dog_atta6	] {ai_charge(10);};
void() dog_atta6	=[	$attack6,	dog_atta7	] {ai_charge(10);};
void() dog_atta7	=[	$attack7,	dog_atta8	] {ai_charge(10);};
void() dog_atta8	=[	$attack8,	dog_run1	] {ai_charge(10);};

void() dog_leap1	=[	$leap1,		dog_leap2	]
{
	ai_face();
	
	if (self.flags & FL_ONGROUND)
	{
		self.velocity = '0 0 272';
		self.flags -= FL_ONGROUND;
	}
};
void() dog_leap2	=[	$leap2,		dog_leap3	]
{
	ai_face();

	LeapAttack(Dog_JumpTouch, 320, 208);
};

void() dog_leap3	=[	$leap3,		dog_leap4	] {};
void() dog_leap4	=[	$leap4,		dog_leap5	] {};
void() dog_leap5	=[	$leap5,		dog_leap6	] {};
void() dog_leap6	=[	$leap6,		dog_leap7	] {};
void() dog_leap7	=[	$leap7,		dog_leap8	] {};
void() dog_leap8	=[	$leap8,		dog_leap9	] {self.oldorigin = self.origin;};
void() dog_leap9	=[	$leap9,		dog_run1	]
{
	if (self.origin != self.oldorigin)
		self.think = dog_leap9;
	else
	{
		self.special_time = time + 1;
		self.touch = SUB_Null;
	}
		
	self.oldorigin = self.origin;
};

void() dog_pain1	=[	$pain1 ,	dog_pain2	] {};
void() dog_pain2	=[	$pain2 ,	dog_pain3	] {};
void() dog_pain3	=[	$pain3 ,	dog_pain4	] {};
void() dog_pain4	=[	$pain4 ,	dog_pain5	] {};
void() dog_pain5	=[	$pain5 ,	dog_pain6	] {};
void() dog_pain6	=[	$pain6 ,	dog_run1	] {};

void() dog_painb1	=[	$painb1 ,	dog_painb2	] {};
void() dog_painb2	=[	$painb2 ,	dog_painb3	] {};
void() dog_painb3	=[	$painb3 ,	dog_painb4	] {ai_pain(4);};
void() dog_painb4	=[	$painb4 ,	dog_painb5	] {ai_pain(12);};
void() dog_painb5	=[	$painb5 ,	dog_painb6	] {ai_pain(12);};
void() dog_painb6	=[	$painb6 ,	dog_painb7	] {ai_pain(2);};
void() dog_painb7	=[	$painb7 ,	dog_painb8	] {};
void() dog_painb8	=[	$painb8 ,	dog_painb9	] {ai_pain(4);};
void() dog_painb9	=[	$painb9 ,	dog_painb10	] {};
void() dog_painb10	=[	$painb10 ,	dog_painb11	] {ai_pain(10);};
void() dog_painb11	=[	$painb11 ,	dog_painb12	] {};
void() dog_painb12	=[	$painb12 ,	dog_painb13	] {};
void() dog_painb13	=[	$painb13 ,	dog_painb14	] {};
void() dog_painb14	=[	$painb14 ,	dog_painb15	] {};
void() dog_painb15	=[	$painb15 ,	dog_painb16	] {};
void() dog_painb16	=[	$painb16 ,	dog_run1	] {};

void(entity attacker, float damage) dog_pain =
{
	sound (self, CHAN_VOICE, "dog/dpain1.wav", 1, ATTN_NORM);

	if (attacker.super_damage_finished > time)
	{
		SUB_PainFinished(1.6, 3);
		dog_painb1();
	}
	else
	{
		SUB_PainFinished(0.6, 3);
		dog_pain1();
	}
};

void() dog_die1		=[	$death1,	dog_die2	] {};
void() dog_die2		=[	$death2,	dog_die3	] {SetUnblocking();};
void() dog_die3		=[	$death3,	dog_die4	] {};
void() dog_die4		=[	$death4,	dog_die5	] {};
void() dog_die5		=[	$death5,	dog_die6	] {};
void() dog_die6		=[	$death6,	dog_die7	] {};
void() dog_die7		=[	$death7,	dog_die8	] {};
void() dog_die8		=[	$death8,	dog_die9	] {};
void() dog_die9		=[	$death9,	dog_die9	] {};

void() dog_dieb1		=[	$deathb1,	dog_dieb2	] {};
void() dog_dieb2		=[	$deathb2,	dog_dieb3	] {SetUnblocking();};
void() dog_dieb3		=[	$deathb3,	dog_dieb4	] {};
void() dog_dieb4		=[	$deathb4,	dog_dieb5	] {};
void() dog_dieb5		=[	$deathb5,	dog_dieb6	] {};
void() dog_dieb6		=[	$deathb6,	dog_dieb7	] {};
void() dog_dieb7		=[	$deathb7,	dog_dieb8	] {};
void() dog_dieb8		=[	$deathb8,	dog_dieb9	] {};
void() dog_dieb9		=[	$deathb9,	dog_dieb9	] {};

void() dog_gib =
{
	sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
	ThrowGib ("progs/gib3.mdl", self.health);
	ThrowGib ("progs/gib3.mdl", self.health);
	ThrowGib ("progs/gib3.mdl", self.health);
	ThrowHead ("progs/h_dog.mdl", self.health);
}

void() dog_die =
{
	// regular death
	sound (self, CHAN_VOICE, "dog/ddeath.wav", 1, ATTN_NORM);
	
	if (random() > 0.5)
		dog_die1 ();
	else
		dog_dieb1 ();
};

//============================================================================

/*
==============
CheckDogMelee

Returns TRUE if a melee attack would hit right now
==============
*/
float()	CheckDogMelee =
{
	if (enemy_range == RANGE_MELEE)
	{	// FIXME: check canreach
		self.attack_state = AS_MELEE;
		return TRUE;
	}
	return FALSE;
};

/*
==============
CheckDogJump

==============
*/
float()	CheckDogJump =
{
	if (!(self.flags & FL_ONGROUND))
		return FALSE;
	if (vlen(self.enemy.origin - self.origin) <= 80)
		return FALSE;

	return CheckLeap(self.enemy, 208);
};

float()	DogCheckAttack =
{
	if (enemy_range > RANGE_NEAR)
		return FALSE;
	
	// if close enough for slashing, go for it
	if (CheckMeleeRange(self.enemy, 96))
	{
		self.attack_state = AS_MELEE;
		return TRUE;
	}
	
	if (self.attack_finished > time || self.special_time > time)
		return FALSE;

	if (CheckLeap(self.enemy, 160))
	{
		self.attack_state = AS_MISSILE;
		return TRUE;
	}

	return FALSE;
};


//===========================================================================

/*QUAKED monster_dog (1 0 0) (-32 -32 -24) (32 32 40) Ambush
*/
void() monster_dog =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model ("progs/h_dog.mdl");
	precache_model ("progs/dog.mdl");

	precache_sound ("dog/dattack1.wav");
	precache_sound ("dog/ddeath.wav");
	precache_sound ("dog/dpain1.wav");
	precache_sound ("dog/dsight.wav");
	precache_sound ("dog/idle.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/dog.mdl");

	setsize (self, '-28 -28 -24', '28 28 24');
	self.health = 36;
	self.gib_health = -54;
	self.pain_threshold = 18;
	self.yaw_speed = 30;

	self.th_stand = dog_stand1;
	self.th_walk = dog_walk1;
	self.th_run = dog_run1;
	self.th_pain = dog_pain;
	self.th_die = dog_die;
	self.th_gib = dog_gib;
	self.th_melee = dog_atta1;
	self.th_missile = dog_leap1;
	self.th_checkatk = DogCheckAttack;

	walkmonster_start();
};
