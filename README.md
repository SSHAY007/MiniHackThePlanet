<h1> SkillHack </h1>
We have adapted skillhack to work for quest_{easy,medium,hard}. For reproducibility, we have built a docker container. 
The the docker image is located in the root of the project.  
<h1> Installation </h1>
This repository is dependent on the MiniHack repo (https://github.com/facebookresearch/minihack) and (Torchbeast).
This is the rootless docker installation. The cluster will not work with docker but with singularity. This is just to show that it will run and achieve similair results.
To build the docker container 

```bash
docker build -t hks -f Dockerfile . 
```
Once the container is build. Navigate to the directory where this repo is cloned and run:
```bash
docker run --mount type=bind,source="$PWD",target=/workspace \
--rm \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-e DISPLAY=$DISPLAY \
-it \
hks
```
This might not work as you may have to expose your display which is not recommended but this will mean you cannot see any GUI through the container.
Thus instead you can run:
```bash
docker run --mount type=bind,source="$PWD",target=/workspace --rm -it hks
```
This will connect you to the running container.

<h1> Running experiments </h1>
To train an option you may need to set the environment variable again:

```bash
expose SKILL_TRANSFER_HOME=$PWD/skill_transfer_weights
```
To train the REINFORCE with baseline (Advantage Actor Critic)
Thereafter you can run:
```bash
python -m agent.polybeast.skill_transfer_polyhydra model=baseline env=mini_skill_fight use_lstm=false total_steps=1e7
```
All the options are pretrained on the cluster and are present here.
To train the HIERARCHICAL KICKSTARTING models you can use:

```bash
python -m agent.polybeast.skill_transfer_polyhydra model=hks env=quest_easy
```

To play using pretrained skills you can run:
```bash
python -m scripts.play_pretrained 
```


<h1> Understanding this repo </h1>
This repo is a very intertwined collections of classes. The driving "main" classes is  

```skill_transfer_learner.py ```
```skill_transfer_env.py ``` 

The batching and queuing functions are handles using torchbeast. 
Torchbeast is a Distributed Scalable Learner and Actor framework that handles the backbone of training. Torchbeast uses 
```skill_transfer_env.py ``` to to create the environments. These environments are vectorized by having a class that 
reconciles in ```agent/common/envs/tasks.py ```. Once the environment sever is started the actors can connect to it and start the
rollouts for each actor. 

```actor.run()``` actually performs the rollouts using the Batching queue and inference queue. In the ```skill_transfer_learner.py ``` holds all the HKS , FOC
and baseline loss. The actual loss calculates are in ```agent/polybeast/models/losses.py```.

The models are all parents of a base ```MiniHackAgent```. The base models inherit this class. Then ```HKS,baseline,foc``` are all child
classes and build upon the base class.

Once the options are trained the hierarchical models finds them using a ```tasks.json```. This allows as to add any skill as a subtask. Then these
models looks at the paths for the pretrained skills. 

Anything after is the original repo which is from UCL Skillhack repository.

<h1> SkillHack </h1>

Source code for [Hierarchical Kickstarting for Skill Transfer in Reinforcement Learning](https://arxiv.org/abs/2207.11584) (CoLLAs 2022).
![alt text](https://github.com/ucl-dark/skillhack/blob/main/docs/skills_15.png?raw=true)

SkillHack is a repository for skill based learning based on MiniHack and the NetHack Learning Environment (NLE).  SkillHack consists of 16 simple skill acquistion environments and 8 complex task environments.  The task environments are difficult to solve due to the large state-action space and sparsity of rewards, but can be made tractable by transferring knowledge gained from the simpler skill acquistion environments.





<h1>How to run a Skill Transfer experiment</h1>
First, create a directory to store pretrained skills in and set the environment variable SKILL_TRANSFER_HOME to point to this directory.
This directory must also include a file called skill_config.yaml.  A default setting for this file can be found in the same directory as this readme.

Next, this directory must be populated with pretrained skill experts.  These are obtained by running skill_transfer_polyhydra.py on a skill-specific environment.

<h2>Full Skill Expert Training Walkthrough</h2>

In this example we train the <i>fight</i> skill.

First, the agent is trained with the following command

```
python -m agent.polybeast.skill_transfer_polyhydra model=baseline env=mini_skill_fight use_lstm=false total_steps=1e7
```

Once the agent is trained, the final weights are automatically copied to SKILL_TRANSFER_HOME and renamed to the name of the skill environment.
So in this example, the skill would be saved at
```
${SKILL_TRANSFER_HOME}/mini_skill_fight.tar
```

If there already exists a file with this name in SKILL_TRANSFER_HOME (i.e. if you've already trained an agent on this skill) then the new skill expert is saved as

```
${SKILL_TRANSFER_HOME}/${ENV_NAME}_${CURRENT_TIME_SECONDS}.tar
```
Tasks that make use of skills will use the path given in the first example (i.e. without the current time).  If you want to use your newer agent, you need to delete the old file and rename the new file to remove the time from it.


<h2>Training other skills</h2>
Repeat this for all skills.

Remember all skills need to be trained with use_lstm=false

The full list of skills to be trained is
<ul>
<li>mini_skill_apply_frost_horn
<li>mini_skill_eat
<li>mini_skill_fight
<li>mini_skill_nav_blind
<li>mini_skill_nav_lava
<li>mini_skill_nav_lava_to_amulet
<li>mini_skill_nav_water
<li>mini_skill_pick_up
<li>mini_skill_put_on
<li>mini_skill_take_off
<li>mini_skill_throw
<li>mini_skill_unlock
<li>mini_skill_wear
<li>mini_skill_wield
<li>mini_skill_zap_cold
<li>mini_skill_zap_death
</ul>

<h2>Training on Tasks</h2>

If the relevant skills for the environment are not present in SKILL_TRANSFER_HOME an error will be shown indicating which skill is missing.
The skill transfer specific models are
<ul>
  <li>foc: Options Framework</li>
  <li>ks: Kickstarting</li>
  <li>hks: Hierarchical Kickstarting</li>
</ul>

The tasks created for skill transfer are
<ul>
  <li>mini_simple_seq: Battle</li>
  <li>mini_simple_union: Over or Around</li>
  <li>mini_simple_intersection: Prepare for Battle</li>
  <li>mini_simple_random: Target Practice</li>
  <li>mini_lc_freeze: Frozen Lava Cross</li>
  <li>mini_medusa: Medusa</li>
  <li>mini_mimic: Identify Mimic</li>
  <li>mini_seamonsters: Sea Monsters</li>
</ul>

So, for example, to run hierarchical kickstarting on the Target Practice environment, one would call
```
python -m agent.polybeast.skill_transfer_polyhydra model=hks env=mini_simple_random
```
With all other parameters being able to be set in the same way as with polyhydra.py


<h2>Training on Tasks</h2>
The runs from the paper can be repeated with the following command.  If you don't want to run with wandb, set wandb=false.

```
python -m agent.polybeast.skill_transfer_polyhydra --multirun model=ks,foc,hks,baseline env=mini_simple_seq,mini_simple_intersection,mini_simple_union,mini_simple_random,mini_lc_freeze,mini_medusa,mini_mimic,mini_seamonsters name=1,2,3,4,5,6,7,8,9,10,11,12 total_steps=2.5e8 group=<YOUR_WANDB_GROUP> hks_max_uniform_weight=20 hks_min_uniform_prop=0 train_with_all_skills=false ks_min_lambda_prop=0.05 hks_max_uniform_time=2e7 entity=<YOUR_WANDB_ENTITY> project=<YOUR_WANDB_PROJECT>
```


<h2> Final Notes </h2>
<ul>
    <li>If you want to train with the fixed version of nav_blind, go to data/tasks/tasks.json and replace mini_skill_nav_blind with mini_skill_nav_blind_fixed</li>
</ul>

