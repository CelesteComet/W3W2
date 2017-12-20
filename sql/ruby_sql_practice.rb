require 'sqlite3'
require 'singleton'

class QuestionsDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :id, :fname, :lname

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def create
    raise "#{self} already in database" if @id
    QuestionsDBConnection.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDBConnection.instance.last_insert_row_id
  end

  def self.find_by_name(fname, lname)
    QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = (?) AND lname = (?)
    SQL
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

end

# Bruce.authored_questions = [q1, q2]

class Question

  attr_accessor :title, :body, :author_id

  def initialize(options)
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def create
    raise "#{self} already in database" if @id
    QuestionsDBConnection.instance.execute(<<-SQL, @title, @body, @author_id)
      INSERT INTO
        questions (title, body, author_id)
      VALUES
        (?, ?, ?)
    SQL
    @id = QuestionsDBConnection.instance.last_insert_row_id
  end

  def author #self.find_by_author_id gives an array of all possible questions
            #choose an index to call when using the author method
    names_arr = QuestionsDBConnection.instance.execute(<<-SQL, @author_id)
      SELECT
        fname, lname
      FROM
        users
      WHERE
        users.id = (?)
    SQL
    names_arr.first.values.join(' ')
  end

  def self.find_by_author_id(author_id)
    questions_of_author = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
        SELECT
          *
        FROM
          questions
        WHERE
          id = (?)
      SQL
    questions_of_author.map {|datum| self.new(datum)}
  end
end

class Reply

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_reply_id = options['parent_reply_id']
    @author_id = options['author_id']
    @body = options['body']
  end

  def author #self.find_by_author_id gives an array of all possible questions
            #choose an index to call when using the author method
    names_arr = QuestionsDBConnection.instance.execute(<<-SQL, @author_id)
      SELECT
        fname, lname
      FROM
        users
      WHERE
        id = (?)
    SQL
    names_arr.first.values.join(' ')
  end

  def question #same idea as self.find_by_author_id
    names_arr = QuestionsDBConnection.instance.execute(<<-SQL, @question_id)
      SELECT
        title, body
      FROM
        questions
      WHERE
        id = (?)
    SQL
    names_arr.first.values.join(' ')
  end

  def self.find_by_question_id(question_id)
    replies_of_question = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
        SELECT
          *
        FROM
          replies
        WHERE
          question_id = (?)
      SQL
    replies_of_question.map {|datum| self.new(datum)}
  end

  def self.find_by_user_id(user_id)
    replies_of_user = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
        SELECT
          *
        FROM
          replies
        WHERE
          author_id = (?)
      SQL
    replies_of_user.map {|datum| self.new(datum)}
  end

  def parent_reply
    result = QuestionsDBConnection.instance.execute(<<-SQL, @parent_reply_id)
      SELECT
        body
      FROM
        replies
      WHERE
        id = (?)
    SQL
    result.first.values.first
  end

  def child_replies
    QuestionsDBConnection.instance.execute(<<-SQL, @id)
      SELECT
        body
      FROM
        replies
      WHERE
        parent_reply_id = (?)
    SQL
  end
end

class QuestionFollow

  attr_accessor :question_id, :user_id

  def initialize(question_id, user_id)
    # question_id INTEGER NOT NULL,
    # user_id INTEGER NOT NULL,
    @question_id = question_id
    @user_id = user_id
  end

  def self.followers_for_question_id(question_id)
    QuestionsDBConnection.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        questions
      INNER JOIN
        users
    SQL
  end
end
