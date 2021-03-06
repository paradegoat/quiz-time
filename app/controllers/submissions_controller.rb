class SubmissionsController < ApplicationController
  before_action :require_user
  before_action :require_admin, only: :index
  before_action :require_no_open_submissions, only: [:create, :show]
  before_action :set_submission, only: [:show, :edit, :update, :destroy]

  # New is implemented in quizzes#show method
  #def new
  #end

  # Should only be accessible if a user has not made a previous submission
  # with this quiz id and has no other quizzes open
  def create
    @submission = Submission.new(submission_params)
    @quiz = Quiz.find(@submission[:quiz_id])

    if(@quiz && @submission)
      @qa_hash = json_to_hasharray(@quiz.qajson)
      @submission[:user_id] = current_user.id
      @submission[:qajson] = @quiz.qajson
      @submission[:complete] = false
      @submission[:correct] = 0
      @submission[:possible] = @qa_hash.count if @qa_hash

      if(@submission.save)
        render :edit
      else
        redirect_to user_path(current_user), notice: "Error creating new submission."
      end
    else
      redirect_to user_path(current_user), notice: "Invalid quiz ID."
    end
  end

  def edit
    @quiz = Quiz.find(@submission[:quiz_id])
    #Shuffled here to keep edit template render and javascript scoring in tact
    @qa_hash = json_to_hasharray(@submission.qajson).shuffle!
  end

  def update
    @quiz = Quiz.find(@submission[:quiz_id])
    if @submission.update(submission_params)
      @qa_hash= json_to_hasharray(@submission.qajson)
      @submission[:correct] = count_json_correct(@qa_hash)
      @submission[:possible] = @qa_hash.count
      if @submission.save
        if @submission[:complete]
          render :show, notice: "Quiz has been submitted successfully."
        else render :edit, notice: "Quiz progress has been saved successfully." end
      else
        render :edit, notice: "Error submitting quiz."
      end
    else
      render :edit, notice: "Error submitting quiz."
    end
  end

  def show
   @quiz = Quiz.find(@submission[:quiz_id])
   @qa_hash = json_to_hasharray(@submission.qajson)
  end

  def destroy
  end

  def index
  end

  private

  def submission_params
    params.require(:submission).permit(:quiz_id, :qajson, :complete)
  end

  def set_submission
    @submission = Submission.find(params[:id])
  end

  #Count number of correct answers in submission qajson
  def count_json_correct(qajson_array)
    result = 0
    qajson_array.each do |hash|
        if hash["selection"] == hash["correct"] then result += 1 end
    end
    puts result
    result
  end
end
