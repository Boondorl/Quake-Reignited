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

WIZARD (Scrag)

==============================================================================
*/

$cd id1/models/a_wizard
$origin 0 0 24
$base wizbase
$skin wizbase

$frame hover1 hover2 hover3 hover4 hover5 hover6 hover7 hover8
$frame hover9 hover10 hover11 hover12 hover13 hover14 hover15

$frame fly1 fly2 fly3 fly4 fly5 fly6 fly7 fly8 fly9 fly10
$frame fly11 fly12 fly13 fly14

$frame magatt1 magatt2 magatt3 magatt4 magatt5 magatt6 magatt7
$frame magatt8 magatt9 magatt10 magatt11 magatt12 magatt13

$frame pain1 pain2 pain3 pain4

$frame death1 death2 death3 death4 death5 death6 death7 death8

/*
==============================================================================

WIZARD

If the player moves behind cover before the missile is launched, launch it
at the last visible spot with no velocity leading, in hopes that the player
will duck back out and catch it.
==============================================================================
*/

float() ShouldStrafe =
{
	if (self.special <= time)
		return FALSE;
	
	return range(self.enemy) <= RANGE_NEAR;
};

void() AttackStrafe =
{
	if (visible(self.enemy, FALSE))
		self.special = time + 2;
	
	if (range(self.enemy) >= RANGE_MID)
	{
		ai_face();
		return;
	}
	if (HasInvisible(self.enemy))
	{
		ai_face();
		return;
	}
	
	movedist = 8;
	ai_run_slide();
};

void() wiz_touch =
{
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		// trigger field, do nothing
		return;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (15);
		T_Damage (other, self, self.owner, 15, 25, FALSE);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_WIZSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);
};

void(float left) WizAttack =
{
	sound (self, CHAN_WEAPON, "wizard/wattack.wav", 1, ATTN_NORM);
	self.effects |= EF_MUZZLEFLASH;

	local float side = 14;
	if (left)
		side = -side;
	
	makevectors (self.angles);
	
	local entity missile = FireProjectileAtEnemy(self.origin+'0 0 30'+v_forward*14+v_right*side, '0 0 0', 750, 6, "progs/w_spike.mdl", skill == 3, FALSE);
	missile.classname = "wizspike";
	missile.touch = wiz_touch;
}

void() wiz_run1;
void() wiz_side1;

void() WizMove = 
{
	if (!self.attack_state)
		self.attack_state = AS_STRAIGHT;
	
	if (visible(self.enemy, FALSE))
		self.special = time + 2;
	
	if (self.in_attack)
	{
		ai_run(0);
		return;
	}
	
	if (self.attack_state == AS_STRAIGHT)
	{
		if (ShouldStrafe())
		{
			self.attack_state = AS_SLIDING;
			wiz_side1();
			return;
		}
		
		ai_run(16);
	}
	else if (self.attack_state == AS_SLIDING)
	{
		if (!ShouldStrafe())
		{
			self.attack_state = AS_STRAIGHT;
			wiz_run1();
			return;
		}
		
		if (self.cnt <= time && self.special <= time + 1)
		{
			self.cnt = time + 1;
			self.lefty = !self.lefty;
		}
		
		ai_run(8);
	}
};

/*
=============
LaunchMissile

Sets the given entities velocity and angles so that it will hit self.enemy
if self.enemy maintains it's current velocity
0.1 is moderately accurate, 0.0 is totally accurate
=============
*/
void(entity missile, float mspeed, float accuracy) LaunchMissile =
{
	local vector vec, move;
	local float fly;

	makevectors (self.angles);

	// set missile speed
	vec = self.enemy.origin + self.enemy.mins + self.enemy.size * 0.7 - missile.origin;

	// calc approximate time for missile to reach vec
	fly = vlen (vec) / mspeed;

	// get the entities xy velocity
	move = self.enemy.velocity;
	move_z = 0;

	// project the target forward in time
	vec = vec + move * fly;

	vec = normalize(vec);
	vec = vec + accuracy*v_up*(random()- 0.5) + accuracy*v_right*(random()- 0.5);

	missile.velocity = vec * mspeed;

	missile.angles = '0 0 0';
	missile.angles_y = vectoyaw(missile.velocity);

	// set missile duration
	missile.nextthink = time + 5;
	missile.think = SUB_Remove;
};

float(vector orig) WizLOS =
{
	makevectors('0 1 0' * vectoyaw(self.enemy.origin-orig));
	
	local vector o = orig + '0 0 30' + v_forward*14;
	traceline (o + v_right*14, self.enemy.origin, FALSE, self);
	if (trace_ent != self.enemy)
		return FALSE;
	
	traceline (o - v_right*14, self.enemy.origin, FALSE, self);
	return trace_ent == self.enemy;
};

/*
=================
WizardCheckAttack
=================
*/
float()	WizardCheckAttack =
{
	if (self.attack_finished > time || enemy_range == RANGE_FAR)
		return FALSE;
	
	local float chance;
	if (enemy_range == RANGE_MELEE)
		chance = 0.9;
	else if (enemy_range == RANGE_NEAR)
		chance = 0.6;
	else if (enemy_range == RANGE_MID)
		chance = 0.2;

	if (random() < chance)
	{
		if (!WizLOS(self.origin))
			return FALSE;
		
		self.attack_state = AS_MISSILE;
		SUB_AttackFinished(1+random(), 1);
		return TRUE;
	}

	return FALSE;
};

/*
=================
WizardAttackFinished
=================
*/
void()	WizardAttackFinished =
{
	if (ShouldStrafe())
	{
		self.attack_state = AS_SLIDING;
		self.think = wiz_side1;
	}
};

/*
==============================================================================

FAST ATTACKS

==============================================================================
*/

void() Wiz_FastFire =
{
	local vector vec;
	local vector dst;

	if (self.owner.health > 0)
	{
		self.owner.effects = self.owner.effects | EF_MUZZLEFLASH;

		makevectors (self.enemy.angles);
		dst = self.enemy.origin - 13*self.movedir;

		vec = normalize(dst - self.origin);
		sound (self, CHAN_WEAPON, "wizard/wattack.wav", 1, ATTN_NORM);
		launch_spike (self.origin, vec);
		newmis.velocity = vec*600;
		newmis.owner = self.owner;
		newmis.classname = "wizspike";
		setmodel (newmis, "progs/w_spike.mdl");
		setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	}

	remove (self);
};


void() Wiz_StartFast =
{
	local entity missile;

	sound (self, CHAN_WEAPON, "wizard/wattack.wav", 1, ATTN_NORM);
	self.v_angle = self.angles;
	makevectors (self.angles);

	missile = spawn ();
	missile.owner = self;
	missile.nextthink = time + 0.6;
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin + '0 0 30' + v_forward*14 + v_right*14);
	missile.enemy = self.enemy;
	missile.nextthink = time + 0.8;
	missile.think = Wiz_FastFire;
	missile.movedir = v_right;

	missile = spawn ();
	missile.owner = self;
	missile.nextthink = time + 1;
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin + '0 0 30' + v_forward*14 + v_right* -14);
	missile.enemy = self.enemy;
	missile.nextthink = time + 0.3;
	missile.think = Wiz_FastFire;
	missile.movedir = VEC_ORIGIN - v_right;
};



void() Wiz_idlesound =
{
	if (self.sight_finished > time)
		return;
	
	local float wr;

	wr = random() * 5;

	if (self.waitmin < time)
	{
	 	self.waitmin = time + 2;
	 	if (wr > 4.5)
	 		sound (self, CHAN_VOICE, "wizard/widle1.wav", 1,  ATTN_IDLE);
	 	if (wr < 1.5)
	 		sound (self, CHAN_VOICE, "wizard/widle2.wav", 1, ATTN_IDLE);
	}
	return;
};

void()	wiz_stand1	=[	$hover1,		wiz_stand2	] {ai_stand();};
void()	wiz_stand2	=[	$hover2,		wiz_stand3	] {ai_stand();};
void()	wiz_stand3	=[	$hover3,		wiz_stand4	] {ai_stand();};
void()	wiz_stand4	=[	$hover4,		wiz_stand5	] {ai_stand();};
void()	wiz_stand5	=[	$hover5,		wiz_stand6	] {ai_stand();};
void()	wiz_stand6	=[	$hover6,		wiz_stand7	] {ai_stand();};
void()	wiz_stand7	=[	$hover7,		wiz_stand8	] {ai_stand();};
void()	wiz_stand8	=[	$hover8,		wiz_stand1	] {ai_stand();};

void()	wiz_walk1	=[	$hover1,		wiz_walk2	]
{
	Wiz_idlesound();
	ai_walk(8);
};
void()	wiz_walk2	=[	$hover2,		wiz_walk3	] {ai_walk(8);};
void()	wiz_walk3	=[	$hover3,		wiz_walk4	] {ai_walk(8);};
void()	wiz_walk4	=[	$hover4,		wiz_walk5	] {ai_walk(8);};
void()	wiz_walk5	=[	$hover5,		wiz_walk6	] {ai_walk(8);};
void()	wiz_walk6	=[	$hover6,		wiz_walk7	] {ai_walk(8);};
void()	wiz_walk7	=[	$hover7,		wiz_walk8	] {ai_walk(8);};
void()	wiz_walk8	=[	$hover8,		wiz_walk1	] {ai_walk(8);};

void()	wiz_side1	=[	$hover1,		wiz_side2	]
{
	Wiz_idlesound();
	WizMove();
};
void()	wiz_side2	=[	$hover2,		wiz_side3	] {WizMove();};
void()	wiz_side3	=[	$hover3,		wiz_side4	] {WizMove();};
void()	wiz_side4	=[	$hover4,		wiz_side5	] {WizMove();};
void()	wiz_side5	=[	$hover5,		wiz_side6	] {WizMove();};
void()	wiz_side6	=[	$hover6,		wiz_side7	] {WizMove();};
void()	wiz_side7	=[	$hover7,		wiz_side8	] {WizMove();};
void()	wiz_side8	=[	$hover8,		wiz_side1	] {WizMove();};

void()	wiz_run1	=[	$fly1,		wiz_run2	]
{
	Wiz_idlesound();
	WizMove();
};
void()	wiz_run2	=[	$fly2,		wiz_run3	] {WizMove();};
void()	wiz_run3	=[	$fly3,		wiz_run4	] {WizMove();};
void()	wiz_run4	=[	$fly4,		wiz_run5	] {WizMove();};
void()	wiz_run5	=[	$fly5,		wiz_run6	] {WizMove();};
void()	wiz_run6	=[	$fly6,		wiz_run7	] {WizMove();};
void()	wiz_run7	=[	$fly7,		wiz_run8	] {WizMove();};
void()	wiz_run8	=[	$fly8,		wiz_run9	] {WizMove();};
void()	wiz_run9	=[	$fly9,		wiz_run10	] {WizMove();};
void()	wiz_run10	=[	$fly10,		wiz_run11	] {WizMove();};
void()	wiz_run11	=[	$fly11,		wiz_run12	] {WizMove();};
void()	wiz_run12	=[	$fly12,		wiz_run13	] {WizMove();};
void()	wiz_run13	=[	$fly13,		wiz_run14	] {WizMove();};
void()	wiz_run14	=[	$fly14,		wiz_run1	] {WizMove();};

void()	wiz_fast1	=[	$magatt1,		wiz_fast2	]
{
	makevectors('0 1 0' * self.ideal_yaw);
	local vector dir = v_right * 30;
	if (self.lefty)
		dir = -dir;
	
	local float cur = WizLOS(self.origin+dir);
	local float new = WizLOS(self.origin-dir);
	if ((cur && new) || (!cur && !new))
	{
		if (random() < 0.33335)
			self.lefty = !self.lefty;
	}
	else if (!cur && new)
		self.lefty = !self.lefty;
	
	AttackStrafe();
};
void()	wiz_fast2	=[	$magatt2,		wiz_fast3	] {AttackStrafe();};
void()	wiz_fast3	=[	$magatt3,		wiz_fast4	] {AttackStrafe();};
void()	wiz_fast4	=[	$magatt4,		wiz_fast5	] {AttackStrafe();WizAttack(FALSE);};
void()	wiz_fast5	=[	$magatt5,		wiz_fast6	] {AttackStrafe();};
void()	wiz_fast6	=[	$magatt6,		wiz_fast7	] {AttackStrafe();};
void()	wiz_fast7	=[	$magatt5,		wiz_fast8	] {AttackStrafe();};
void()	wiz_fast8	=[	$magatt4,		wiz_fast9	] {AttackStrafe();};
void()	wiz_fast9	=[	$magatt3,		wiz_fast10	] {AttackStrafe();WizAttack(TRUE);};
void()	wiz_fast10	=[	$magatt2,		wiz_run1	] {AttackStrafe();WizardAttackFinished();};

void()	wiz_pain1	=[	$pain1,		wiz_pain2	] {};
void()	wiz_pain2	=[	$pain2,		wiz_pain3	] {};
void()	wiz_pain3	=[	$pain3,		wiz_pain4	] {};
void()	wiz_pain4	=[	$pain4,		wiz_run1	] {};

void()	wiz_death1	=[	$death1,		wiz_death2	]
{
	self.velocity_x = -200 + 400*random();
	self.velocity_y = -200 + 400*random();
	self.velocity_z = 100 + 100*random();
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	sound (self, CHAN_VOICE, "wizard/wdeath.wav", 1, ATTN_NORM);
};
void()	wiz_death2	=[	$death2,		wiz_death3	] {SetUnblocking();};
void()	wiz_death3	=[	$death3,		wiz_death4	] {};
void()	wiz_death4	=[	$death4,		wiz_death5	] {};
void()	wiz_death5	=[	$death5,		wiz_death6	] {};
void()	wiz_death6	=[	$death6,		wiz_death7	] {};
void()	wiz_death7	=[	$death7,		wiz_death8	] {};
void()	wiz_death8	=[	$death8,		wiz_death8	] {};

void() wiz_gib =
{
	sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
	ThrowHead ("progs/h_wizard.mdl", self.health);
	ThrowGib ("progs/gib2.mdl", self.health);
	ThrowGib ("progs/gib2.mdl", self.health);
	ThrowGib ("progs/gib2.mdl", self.health);
};

void() wiz_die =
{
	wiz_death1 ();
};


void(entity attacker, float damage) Wiz_Pain =
{
	SUB_PainFinished(1, 3);
	sound (self, CHAN_VOICE, "wizard/wpain.wav", 1, ATTN_NORM);

	wiz_pain1 ();
};


void() Wiz_Missile =
{
	wiz_fast1();
};

/*QUAKED monster_wizard (1 0 0) (-16 -16 -24) (16 16 40) Ambush
*/
void() monster_wizard =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model ("progs/wizard.mdl");
	precache_model ("progs/h_wizard.mdl");
	precache_model ("progs/w_spike.mdl");

	// used by c code
	precache_sound ("wizard/hit.wav");
	precache_sound ("wizard/wattack.wav");
	precache_sound ("wizard/wdeath.wav");
	precache_sound ("wizard/widle1.wav");
	precache_sound ("wizard/widle2.wav");
	precache_sound ("wizard/wpain.wav");
	precache_sound ("wizard/wsight.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/wizard.mdl");

	setsize (self, '-16 -16 -24', '16 16 40');
	self.health = 72;
	self.gib_health = -54;
	self.pain_threshold = 50;

	self.th_stand = wiz_stand1;
	self.th_walk = wiz_walk1;
	self.th_run = wiz_run1;
	self.th_missile = Wiz_Missile;
	self.th_pain = Wiz_Pain;
	self.th_die = wiz_die;
	self.th_gib = wiz_gib;
	self.th_checkatk = WizardCheckAttack;

	flymonster_start ();
};
