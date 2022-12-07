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

A monster is in fight mode if it thinks it can effectively attack its
enemy.

When it decides it can't attack, it goes into hunt mode.

*/

float(float v) anglemod;

void() knight_atk1;
void() knight_runatk1;
void() ogre_smash1;
void() ogre_swing1;

void() sham_smash1;
void() sham_swingr1;
void() sham_swingl1;

float()	DemonCheckAttack;
void(float side)	Demon_Melee;
float(entity targ, float range) CheckMeleeRange;

void(vector dest) ChooseTurn;

void() ai_face;


float	enemy_vis, enemy_infront, enemy_range;
float	enemy_yaw;


void() knight_attack =
{
	// decide if now is a good swing time
	if (vlen(self.enemy.origin - self.origin) < 80)
		knight_atk1 ();
	else
		knight_runatk1 ();
};

//=============================================================================

float() CheckLoS;
/*
===========
CheckAttack

The player is in view, so decide to move or launch an attack
Returns FALSE if movement should continue
============
*/
float() CheckAttack =
{
	if (enemy_range == RANGE_FAR)
		return FALSE;

	if (self.th_melee)
	{
		if (CheckMeleeRange(self.enemy, 100))
		{
			self.attack_state = AS_MELEE;
			return TRUE;
		}
	}

	// missile attack
	if (!self.th_missile || self.attack_finished > time)
		return FALSE;

	local float chance;
	if (enemy_range == RANGE_MELEE)
		chance = 0.9;
	else if (enemy_range == RANGE_NEAR)
	{
		if (self.th_melee)
			chance = 0.2;
		else
			chance = 0.4;
	}
	else if (enemy_range == RANGE_MID)
	{
		if (self.th_melee)
			chance = 0.05;
		else
			chance = 0.1;
	}

	if (random() < chance)
	{
		if (self.th_checklos)
		{
			if (!self.th_checklos())
				return FALSE;
		}
		else if (!CheckLoS())
			return FALSE;
		
		self.attack_state = AS_MISSILE;
		SUB_AttackFinished (2 + random(), 0, FALSE);
		return TRUE;
	}

	return FALSE;
};

/*
=============
ai_charge

The monster is in a melee attack, so get as close as possible to .enemy
=============
*/
float (entity targ, float ignore_water) visible;
float(entity targ) infront;
float(entity targ) range;
float(entity targ) HasInvisible;
void(float damage, float dist, float pain) MeleeAttack;

/*
=============
ai_face

Stay facing the enemy, but only if we have sight
=============
*/
void() ai_face =
{
	if (self.classname != "monster_boss")
	{
		if (self.in_attack)
		{
			if (HasInvisible(self.enemy))
			{
				ChangeYaw();
				return;
			}
		}
		
		if (!visible(self.enemy, TRUE))
		{
			ChangeYaw();
			return;
		}
	}
	
	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	ChangeYaw();
};

void(float d) ai_charge =
{
	ai_face ();
	// done in C code...
	walkmove(self.ideal_yaw, d);
};

void() ai_charge_side =
{
	// aim to the left of the enemy for a flyby

	ai_face();

	walkmove(self.ideal_yaw + 5, 20);
};


/*
=============
ai_melee

=============
*/
void() ai_melee =
{
	if (!self.enemy)
		// removed before stroke
		return;

	MeleeAttack(5, 80, 20);
};


void() ai_melee_side =
{
	if (!self.enemy)
		return;		// removed before stroke

	ai_charge_side();
	MeleeAttack(5, 80, 20);
};


//=============================================================================

/*
===========
SoldierCheckAttack

The player is in view, so decide to move or launch an attack
Returns FALSE if movement should continue
============
*/
float() SoldierCheckAttack =
{
	if (self.attack_finished > time || enemy_range == RANGE_FAR)
		return FALSE;

	local float chance;
	if (enemy_range == RANGE_MELEE)
		chance = 0.9;
	else if (enemy_range == RANGE_NEAR)
		chance = 0.4;
	else if (enemy_range == RANGE_MID)
		chance = 0.05;

	if (random () < chance)
	{
		if (self.th_checklos)
		{
			if (!self.th_checklos())
				return FALSE;
		}
		
		self.attack_state = AS_MISSILE;
		SUB_AttackFinished (0.9+random(), 0.9, FALSE);
		return TRUE;
	}

	return FALSE;
};
//=============================================================================

/*
===========
ShamCheckAttack

The player is in view, so decide to move or launch an attack
Returns FALSE if movement should continue
============
*/
float() sham_los;
float(entity e, float melee, float charge) CheckChargeAttack;
float() ShamCheckAttack =
{
	if (vlen(self.enemy.origin-self.origin) > 200)
		self.cnt = 0;
	
	if (enemy_range == RANGE_FAR)
		return FALSE;
	if (vlen(self.enemy.origin+'0 0 16' - (self.origin+'0 0 40')) > 600)
		return FALSE;

	if (self.special_time <= time)
	{
		if (CheckChargeAttack(self.enemy, 120, 160))
		{
			self.special = TRUE;
			self.attack_state = AS_MELEE;
			return TRUE;
		}
	}
	
	if (self.cnt < 2)
	{
		if (CheckMeleeRange(self.enemy, 120))
		{
			self.attack_state = AS_MELEE;
			return TRUE;
		}
	}
	
	if (self.attack_finished > time)
		return FALSE;

	if (!sham_los())
		return FALSE;

	self.attack_state = AS_MISSILE;
	SUB_AttackFinished(1.7+random(), 1.7, FALSE);
	return TRUE;
};

//============================================================================

/*
===========
OgreCheckAttack

The player is in view, so decide to move or launch an attack
Returns FALSE if movement should continue
============
*/
float() ogre_los;
float() OgreCheckAttack =
{
	if (enemy_range == RANGE_FAR)
		return FALSE;
	
	if (CheckMeleeRange(self.enemy, 100))
	{
		self.attack_state = AS_MELEE;
		return TRUE;
	}

	if (self.attack_finished > time)
		return FALSE;
	
	if (!ogre_los())
		return FALSE;

	self.attack_state = AS_MISSILE;
	SUB_AttackFinished (1.5+random(), 1.5, FALSE);
	return TRUE;
};
