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

FISH (Rotfish)

==============================================================================
*/

$cd id1/models/fish
$origin 0 0 24
$base base
$skin skin

$frame attack1 attack2 attack3 attack4 attack5 attack6
$frame attack7 attack8 attack9 attack10 attack11 attack12 attack13
$frame attack14 attack15 attack16 attack17 attack18

$frame death1 death2 death3 death4 death5 death6 death7
$frame death8 death9 death10 death11 death12 death13 death14 death15
$frame death16 death17 death18 death19 death20 death21

$frame swim1 swim2 swim3 swim4 swim5 swim6 swim7 swim8
$frame swim9 swim10 swim11 swim12 swim13 swim14 swim15 swim16 swim17
$frame swim18

$frame pain1 pain2 pain3 pain4 pain5 pain6 pain7 pain8
$frame pain9

void() swimmonster_start;

void() f_stand1  =[      $swim1, f_stand2 ] {ai_stand();};
void() f_stand2  =[      $swim2, f_stand3 ] {ai_stand();};
void() f_stand3  =[      $swim3, f_stand4 ] {ai_stand();};
void() f_stand4  =[      $swim4, f_stand5 ] {ai_stand();};
void() f_stand5  =[      $swim5, f_stand6 ] {ai_stand();};
void() f_stand6  =[      $swim6, f_stand7 ] {ai_stand();};
void() f_stand7  =[      $swim7, f_stand8 ] {ai_stand();};
void() f_stand8  =[      $swim8, f_stand9 ] {ai_stand();};
void() f_stand9  =[      $swim9, f_stand10  ] {ai_stand();};
void() f_stand10 =[      $swim10, f_stand11 ] {ai_stand();};
void() f_stand11 =[      $swim11, f_stand12 ] {ai_stand();};
void() f_stand12 =[      $swim12, f_stand13 ] {ai_stand();};
void() f_stand13 =[      $swim13, f_stand14 ] {ai_stand();};
void() f_stand14 =[      $swim14, f_stand15 ] {ai_stand();};
void() f_stand15 =[      $swim15, f_stand16 ] {ai_stand();};
void() f_stand16 =[      $swim16, f_stand17 ] {ai_stand();};
void() f_stand17 =[      $swim17, f_stand18 ] {ai_stand();};
void() f_stand18 =[      $swim18, f_stand1 ] {ai_stand();};

void() f_walk1  =[      $swim1, f_walk2 ] {ai_walk(8);};
void() f_walk2  =[      $swim2, f_walk3 ] {ai_walk(8);};
void() f_walk3  =[      $swim3, f_walk4 ] {ai_walk(8);};
void() f_walk4  =[      $swim4, f_walk5 ] {ai_walk(8);};
void() f_walk5  =[      $swim5, f_walk6 ] {ai_walk(8);};
void() f_walk6  =[      $swim6, f_walk7 ] {ai_walk(8);};
void() f_walk7  =[      $swim7, f_walk8 ] {ai_walk(8);};
void() f_walk8  =[      $swim8, f_walk9 ] {ai_walk(8);};
void() f_walk9  =[      $swim9, f_walk10  ] {ai_walk(8);};
void() f_walk10 =[      $swim10, f_walk11 ] {ai_walk(8);};
void() f_walk11 =[      $swim11, f_walk12 ] {ai_walk(8);};
void() f_walk12 =[      $swim12, f_walk13 ] {ai_walk(8);};
void() f_walk13 =[      $swim13, f_walk14 ] {ai_walk(8);};
void() f_walk14 =[      $swim14, f_walk15 ] {ai_walk(8);};
void() f_walk15 =[      $swim15, f_walk16 ] {ai_walk(8);};
void() f_walk16 =[      $swim16, f_walk17 ] {ai_walk(8);};
void() f_walk17 =[      $swim17, f_walk18 ] {ai_walk(8);};
void() f_walk18 =[      $swim18, f_walk1 ] {ai_walk(8);};

void() f_run1  =[      $swim1, f_run2 ]
{
	IdleSound("fish/idle.wav", 0.5);
	ai_run(16);
};
void() f_run2  =[      $swim3, f_run3 ] {ai_run(16);};
void() f_run3  =[      $swim5, f_run4 ] {ai_run(16);};
void() f_run4  =[      $swim7, f_run5 ] {ai_run(16);};
void() f_run5  =[      $swim9, f_run6 ] {ai_run(16);};
void() f_run6  =[      $swim11, f_run7 ] {ai_run(16);};
void() f_run7  =[      $swim13, f_run8 ] {ai_run(16);};
void() f_run8  =[      $swim15, f_run9 ] {ai_run(16);};
void() f_run9  =[      $swim17, f_run1 ] {ai_run(16);};

void() fish_melee =
{
	if (!self.enemy)
		// removed before stroke
		return;

	ai_charge(10);
	sound (self, CHAN_VOICE, "fish/bite.wav", 1, ATTN_NORM);
	MeleeAttack(7, 64, 20);
};

void() f_attack6;
void() f_attack12;

void() f_attack1        =[      $attack1,       f_attack2 ] {ai_charge(10);};
void() f_attack2        =[      $attack2,       f_attack3 ] {ai_charge(10);};
void() f_attack3        =[      $attack3,       f_attack4 ] {fish_melee();};
void() f_attack4        =[      $attack4,       f_attack5 ] {ai_charge(10);};
void() f_attack5        =[      $attack5,       f_run1 ]
{
	ai_charge(10);
	if (InAttackDirection(self.enemy, 60))
	{
		if (CheckMeleeRange(self.enemy, 80))
			self.think = f_attack6;
	}
};
void() f_attack6        =[      $attack6,       f_attack7 ] {ai_charge(10);};
void() f_attack7        =[      $attack7,       f_attack8 ] {ai_charge(10);};
void() f_attack8        =[      $attack8,       f_attack9 ] {ai_charge(10);};
void() f_attack9        =[      $attack9,       f_attack10] {fish_melee();};
void() f_attack10       =[      $attack10,      f_attack11] {ai_charge(10);};
void() f_attack11       =[      $attack11,      f_run1 ]
{
	ai_charge(10);
	if (InAttackDirection(self.enemy, 60))
	{
		if (CheckMeleeRange(self.enemy, 80))
			self.think = f_attack12;
	}
};
void() f_attack12       =[      $attack12,      f_attack13] {ai_charge(10);};
void() f_attack13       =[      $attack13,      f_attack14] {ai_charge(10);};
void() f_attack14       =[      $attack14,      f_attack15] {ai_charge(10);};
void() f_attack15       =[      $attack15,      f_attack16] {fish_melee();};
void() f_attack16       =[      $attack16,      f_attack17] {ai_charge(10);};
void() f_attack17       =[      $attack17,      f_attack18] {ai_charge(10);};
void() f_attack18       =[      $attack18,      f_run1    ] {ai_charge(10);};

void() f_death1 =[      $death1,        f_death2        ]
{
	sound (self, CHAN_VOICE, "fish/death.wav", 1, ATTN_NORM);
};
void() f_death2 =[      $death2,        f_death3        ] {SetUnblocking();};
void() f_death3 =[      $death3,        f_death4        ] {};
void() f_death4 =[      $death4,        f_death5        ] {};
void() f_death5 =[      $death5,        f_death6        ] {};
void() f_death6 =[      $death6,        f_death7        ] {};
void() f_death7 =[      $death7,        f_death8        ] {};
void() f_death8 =[      $death8,        f_death9        ] {};
void() f_death9 =[      $death9,        f_death10       ] {};
void() f_death10 =[      $death10,       f_death11       ] {};
void() f_death11 =[      $death11,       f_death12       ] {};
void() f_death12 =[      $death12,       f_death13       ] {};
void() f_death13 =[      $death13,       f_death14       ] {};
void() f_death14 =[      $death14,       f_death15       ] {};
void() f_death15 =[      $death15,       f_death16       ] {};
void() f_death16 =[      $death16,       f_death17       ] {};
void() f_death17 =[      $death17,       f_death18       ] {};
void() f_death18 =[      $death18,       f_death19       ] {};
void() f_death19 =[      $death19,       f_death20       ] {};
void() f_death20 =[      $death20,       f_death21       ] {};
void() f_death21 =[      $death21,       f_death21       ] {};

void() fish_gib =
{
	sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
	// can't call ThrowHead so remove the entity on the next think
	self.think = SUB_Remove;
	self.nextthink= time + 0.1;
	// throw some normal gibs
	ThrowGib ("progs/gib1.mdl", self.health);
	ThrowGib ("progs/gib2.mdl", self.health);
	ThrowGib ("progs/gib3.mdl", self.health);
};

/* Handle fish death, either die animation or gib. */
void() fish_die =
{
	// run normal death animation
	f_death1();
};

void() f_pain1  =[      $pain1, f_pain2 ] {};
void() f_pain2  =[      $pain2, f_pain3 ] {ai_pain(6);};
void() f_pain3  =[      $pain3, f_pain4 ] {ai_pain(6);};
void() f_pain4  =[      $pain4, f_pain5 ] {ai_pain(6);};
void() f_pain5  =[      $pain5, f_pain6 ] {ai_pain(6);};
void() f_pain6  =[      $pain6, f_pain7 ] {ai_pain(6);};
void() f_pain7  =[      $pain7, f_pain8 ] {ai_pain(6);};
void() f_pain8  =[      $pain8, f_pain9 ] {ai_pain(6);};
void() f_pain9  =[      $pain9, f_run1 ] {ai_pain(6);};

void(entity attacker, float damage)	fish_pain =
{
	SUB_PainFinished(0.9,0.9);
	f_pain1 ();
};

float() fish_checkatk =
{
	if (enemy_range > RANGE_MELEE)
		return FALSE;
	
	if (CheckMeleeRange(self.enemy, 80))
	{
		self.attack_state = AS_MELEE;
		return TRUE;
	}
	
	return FALSE;
};

/*QUAKED monster_fish (1 0 0) (-16 -16 -24) (16 16 24) Ambush
*/
void() monster_fish =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model2 ("progs/fish.mdl");

	precache_sound2 ("fish/death.wav");
	precache_sound2 ("fish/bite.wav");
	precache_sound2 ("fish/idle.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/fish.mdl");

	setsize (self, '-16 -16 -24', '16 16 16');
	self.health = 18;
	self.pain_threshold = 1;
	self.gib_health = -54;

	self.th_stand = f_stand1;
	self.th_walk = f_walk1;
	self.th_run = f_run1;
	self.th_die = fish_die;
	self.th_gib = fish_gib;
	self.th_pain = fish_pain;
	self.th_melee = f_attack1;
	self.th_checkatk = fish_checkatk;

	swimmonster_start ();
};
