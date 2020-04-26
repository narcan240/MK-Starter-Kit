class Battle
  attr_accessor :sides
  attr_accessor :effects
  attr_accessor :wild_pokemon
  attr_accessor :run_attempts

  def initialize(side1, side2)
    @effects = {}
    @sides = [Side.new(self, side1), Side.new(self, side2)]
    @sides[0].index = 0
    @sides[1].index = 1
    @wild_battle = false
    if side2.is_a?(Pokemon)
      @sides[1].trainers[0].wild_pokemon = true
      @sides[1].register_battler(@sides[1].trainers[0].party[0])
      @wild_battle = true
    end
    @wild_pokemon = @sides[1].trainers[0].party[0] if @wild_battle
    @run_attempts = 1
    @break = false
    @ui = UI.new(self)
    @ui.begin_start
    @ui.shiny_sparkle if @wild_pokemon.shiny?
    @ui.finish_start("Wild #{@wild_pokemon.pokemon.species.name} appeared!")
    battler = @sides[0].trainers[0].party.find { |e| !e.egg? && !e.fainted? }
    @sides[0].register_battler(battler)
    @ui.send_out_initial_pokemon("Go! #{battler.name}!", battler)
    main
  end

  def wild_battle?
    return @wild_battle
  end

  def update
    @ui.update
  end

  def message(text)
    @ui.message(text)
  end

  def main
    @commands = []
    loop do
      for side in 0...@sides.size
        for battler in @sides[side].battlers
          if side == 0 # Player side
            get_player_command(battler)
            break if @break
          else # Opposing side
            # Uses random move from moveset.
            get_opponent_command(battler)
          end
        end
      end
      sort_commands
      until @commands.empty?
        process_command(@commands[0])
        @commands.delete_at(0)
      end
    end
  end

  # Sorts all commands (switching, using item, using move) based on
  # precedence, priority, speed, or randomness.
  # Can be used in the middle of a turn too.
  def sort_commands
    precedence = [:switch, :use_item, :use_move]
    # Sort commands based on priority, speed and command type
    @commands.sort! do |a, b|
      if a.type != b.type
        # Lower index => Go sooner (a, b)
        next precedence.index(a.type) <=> precedence.index(b.type)
      elsif a.type == :use_move
        if a.move.priority == b.move.priority
          # Equal priority => Use speed stat
          if a.battler.speed == b.battler.speed
            # Speed tie => Decide randomly
            next rand(2) == 0 ? 1 : -1
          else
            # Higher speed => Go sooner (b, a)
            next b.battler.speed <=> a.battler.speed
          end
        else
          # Higher priority => Go sooner (b, a)
          next b.move.priority <=> a.move.priority
        end
      else
        # Lower index => Go sooner (a, b)
        next @commands.index(a) <=> @commands.index(b)
      end
    end
  end

  def get_player_command(battler)
    loop do
      choice = @ui.choose_command(battler)
      if choice.fight?
        success = get_move_command(battler)
        next if !success
      elsif choice.bag?

      elsif choice.pokemon?

      elsif choice.run?
        if wild_battle?
          escaped = battler.attempt_to_escape(@sides[1].battlers[0])
          if escaped
            @ui.fade_out
            @break = true
            return
          end
        else
          message("No! There's no running\nfrom a TRAINER battle!")
        end
      end
      break
    end
  end

  def get_move_command(battler)
    movechoice = nil
    move = nil
    index = 0
    loop do
      movechoice = @ui.choose_move(battler, index)
      break if movechoice.cancel? # Break out of move choosing loop
      move = battler.moves[movechoice.value]
      if move.pp <= 0
        message("There's no PP left for\nthis move!")
        index = movechoice.value
        next # Go back to @ui.choose_move
      end
      break
    end
    return false if movechoice.cancel? # Go back to @ui.choose_command
    @commands << Command.new(:use_move, battler, move)
    return true
  end

  def get_opponent_command(battler)
    @commands << Command.new(:use_move, battler, battler.moves.sample)
  end

  def process_command(command)
    if command.use_move?
      move = BaseMove.new(self, command.move)
      move.execute(command.battler)
    else
      raise "not yet implemented"
    end
  end
end