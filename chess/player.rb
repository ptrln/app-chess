class Player
  attr_reader :name, :color
  def initialize(name)
    @name = name
  end
  def set_color(color)
    @color = color if @color.nil?
  end

  def end_game(board)
    print_board(board)
    if board.checkmate?(opponent_color)
      puts "Checkmate! #{name} (#{@color.to_s}) wins!"
    elsif board.stalemate?(opponent_color) || board.stalemate?(@color)
      puts "Stalemate! It's a draw!"
    elsif board.draw?
      puts "Drawn! No one wins!"
    end
  end

  def print_board(board)
    puts board.pretty_print
  end

  def invalid_move(from, to)
    s = "That move was invalid. Cannot move from #{from} to #{to}!"
    puts s.colorize(:color => :red)
  end

  def opponent_color
    @color == :white ? :black : :white
  end
end

class HumanPlayer < Player
  def initialize(name = nil)
    name = "Human" if name.nil?
    super(name)
  end

  def make_move(board)
    print_board(board)
    print "#{board.check?(self.color) ? "Check! " : ""}"
    print "Your turn, #{name} (#{@color.to_s})! Please make a move (eg e2, e3): "
    gets.chomp.gsub(/[^A-Za-z0-9]/,' ').split(' ')
  end
end

class ComputerPlayer < Player
  def initialize(name = nil)
    name = "Computer" if name.nil?
    super(name)
  end

  def make_move(board)
    print_board(board)
    random_move(board, board.all_possible_moves(self.color))
  end

  def random_move(board, all_possible_moves)
    return nil if all_possible_moves.empty?
    from = all_possible_moves.keys.sample
    to = all_possible_moves[from].sample
    return Board.coord_to_chess(from), Board.coord_to_chess(to)
  end
end

class AdvancedComputerPlayer < ComputerPlayer
  def initialize(name = nil)
    name = "Advanced Computer" if name.nil?
    super(name)
  end

  def make_move(board)
    print_board(board)
    all_pos = board.all_possible_moves(self.color)
    trimmed = trim_harmful_moves(board, all_pos)
    b = board

    check_move(b, trimmed) || take_move(b, trimmed) || random_move(b, trimmed) ||
      check_move(b, all_pos) || take_move(b, all_pos) || random_move(b, all_pos)
  end

  def trim_harmful_moves(board, all_possible_moves)
    trimmed = {}
    all_possible_moves.each do |from, possible_to|
      safe_moves_to = []
      possible_to.each do |to|
        safe_moves_to << to unless opponent_can_take?(board, from, to)
      end
      trimmed[from] = safe_moves_to unless safe_moves_to.empty?
    end
    trimmed
  end

  def opponent_can_take?(board, from, to)
    oppo_moves = board.trial_board(from, to).all_possible_moves(opponent_color)
    oppo_moves.each do |from, possible_to|
      return true if possible_to.include?(to)
    end
    false
  end

  def check_move(board, all_possible_moves)
    all_possible_moves.each do |from, possible_to|
      possible_to.each do |to|
        if board.move_into_check?(opponent_color, from, to)
          return Board.coord_to_chess(from), Board.coord_to_chess(to)
        end
      end
    end
    nil
  end

  def take_move(board, all_possible_moves)
    all_possible_moves.each do |from, possible_to|
      possible_to.each do |to|
        return Board.coord_to_chess(from), Board.coord_to_chess(to) unless board[to].nil?
      end
    end
    nil
  end

end