# encoding: utf-8
require 'colorize'

class Board
  def initialize(rows = nil)
    @rows = rows.nil? ? Board.starting_grid : rows
  end

  def self.starting_grid
    [ Board.royals(:black),
      [Pawn.new(:black)] * 8,
      [nil] * 8,
      [nil] * 8,
      [nil] * 8,
      [nil] * 8,
      [Pawn.new(:white)] * 8,
      Board.royals(:white) ]
  end

  def self.royals(color)
    [ Rook.new(color),
      Knight.new(color),
      Bishop.new(color),
      Queen.new(color),
      King.new(color),
      Bishop.new(color),
      Knight.new(color),
      Rook.new(color) ]
  end

  def self.chess_to_coord(chess)
    row = 8 - chess[1].to_i
    col = (chess[0].downcase).ord - 'a'.ord
    return row, col
  end

  def self.coord_to_chess(coord)
    alpha = (coord[1] + 'a'.ord).chr
    digit = (8 - coord[0]).to_s
    return alpha + digit
  end

  def valid_from?(player_color, from)
    Board.on_board?(from) && self[from] && self[from].color == player_color
  end

  def valid_to?(player_color, to)
    Board.on_board?(to) && (self[to].nil? || self[to].color != player_color)
  end

  def valid_move?(color, from, to)
    if valid_from?(color, from) && valid_to?(color, to) && from != to
      piece = self[from]
      piece.valid_move?(self, from, to) && !move_into_check?(color, from, to)
    else
      false
    end
  end

  def move_into_check?(player_color, from, to)
    trial_board(from, to).check?(player_color)
  end

  def trial_board(from, to)
    check_board = self.dup
    check_board.commit_move(from, to)
    check_board
  end

  def [](coord)
    @rows[coord[0]][coord[1]]
  end

  def self.on_board?(coords)
    coords.all? { |coord| coord.between?(0,7) }
  end

  #returns true if move successful, else false
  def try_move?(player_color, from, to)
    if valid_move?(player_color, from, to)
      commit_move(from, to)
      true
    else
      false
    end
  end

  def check?(player_color)
    king_coord = king_location(player_color)
    self.each_piece_with_coord do |piece, coord|
      next if piece.color == player_color
      return true if piece.valid_move?(self, coord, king_coord)
    end
    false
  end

  def king_location(player_color)
    self.each_piece_with_coord do |piece, coord|
      return coord if (piece.color == player_color) && piece.is_a?(King)
    end
    raise "KingNotFoundError"
  end

  def checkmate?(checked_color)
    return false unless check?(checked_color)
    all_possible_moves(checked_color).each do |from, possible_moves|
      possible_moves.each do |pos_move|
        return false unless move_into_check?(checked_color, from, pos_move)
      end
    end
    true
  end

  def stalemate?(checked_color)
    return false if check?(checked_color)
    all_possible_moves(checked_color).each do |from, possible_moves|
      possible_moves.each do |pos_move|
        return false unless move_into_check?(checked_color, from, pos_move)
      end
    end
    true
  end

  def all_possible_moves(color)
    all_possible_moves = {}
    self.each_piece_with_coord do |piece, coord|
      next unless piece.color == color
      possible_moves = piece.possible_moves(self.dup, coord)
      all_possible_moves[coord] = possible_moves unless possible_moves.empty?
    end
    all_possible_moves
  end

  def each_piece_with_coord(&proc)
    (0...8).each do |i|
      (0...8).each do |j|
        next if self[[i,j]].nil?
        coord = [i, j]
        proc.call(self[coord], coord)
      end
    end
  end

  def draw?
    kings_count = 0
    others_count = 0
    self.each_piece_with_coord do |piece, coord|
      if piece.is_a?(King)
        kings_count += 1
      else
        others_count += 1
      end
    end
    others_count == 0 && kings_count == 2
  end

  def dup
    Board.new(@rows.map(&:dup))
  end

  def pretty_print
    top = "   #{("a".."h").to_a.join('  ')}\n"
    row_index = 8
    background = [:red, :white]
    char_arr = @rows.map do |row|
      left = "#{row_index} "
      char_row = row.map do |piece|
        background.reverse!
        piece_symbol(piece, background.first)
      end
      row_index -= 1
      background.reverse!
      left + char_row.join('')
    end
    top + char_arr.join("\n")
  end

  def piece_symbol(piece, background_color)
    s = case piece
      when King then " ♚ "
      when Queen then " ♛ "
      when Rook then " ♜ "
      when Bishop then " ♝ "
      when Knight then " ♞ "
      when Pawn then " ♟ "
      else
        "   "
      end
    color = :white
    unless piece.nil?
      piece.color == :white ? color = :light_white : color = :black
    end
    s.colorize(:color => color, :background => background_color)
  end

  protected
  def commit_move(from, to)
    self[to] = self[from]
    self[from] = nil
  end

  def []=(coord, value)
    @rows[coord[0]][coord[1]] = value
  end
end
