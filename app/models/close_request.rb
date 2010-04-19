
class CloseRequest
  include MongoMapper::EmbeddedDocument
  TYPES = %w{dupe ot no_question not_relevant spam}

  key :_id, String
  key :reason, String, :in => TYPES

  key :user_id, String
  belongs_to :user

  validate :should_be_unique
  validate :check_reputation

  protected
  def should_be_unique
    request = self._root_document.close_requests.detect{ |rq| rq.user_id == self.user_id }
    valid = (request.nil? || request.id == self.id)
    unless valid
      self.errors.add(:user, I18n.t("close_requests.model.messages.already_requested"))
    end
    return valid
  end

  def check_reputation

    if ((self._root_document.user_id == self.user_id) && !self.user.can_vote_to_close_own_question_on?(self._root_document.group))
      reputation = self._root_document.group.reputation_constrains["vote_to_close_own_question"]
      self.errors.add(:reputation, I18n.t("users.messages.errors.reputation_needed",
                                          :min_reputation => reputation,
                                          :action => I18n.t("users.actions.close_own_question")))
      return false
    end
    unless self.user.can_vote_to_close_any_question_on?(self._root_document.group)
      reputation = self._root_document.group.reputation_constrains["vote_to_close_any_question"]
            self.errors.add(:reputation, I18n.t("users.messages.errors.reputation_needed",
                                          :min_reputation => reputation,
                                          :action => I18n.t("users.actions.close_any_question")))
      return false
    end
    return true
  end
end
