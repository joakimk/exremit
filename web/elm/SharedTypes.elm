module SharedTypes exposing (..)

import Time exposing (Time)

import SettingsTypes exposing (SettingsMsg, Settings)

type Msg
  = SwitchTab Tab
  | UpdateEnvironment String
  | UpdateSettings Settings
  | UpdateCommits (List Commit)
  | UpdateComments (List Comment)
  | UpdateCommit Commit
  | ShowCommit Int
  | ListMoreCommits Time
  | StartReview Change
  | AbandonReview Change
  | MarkAsReviewed Change
  | MarkAsNew Change
  | MarkCommentAsResolved Change
  | MarkCommentAsNew Change
  | LocationChange String
  | UpdateConnectionStatus Bool
  | StoreLastClickedCommentId Int
  | ChangeSettings SettingsMsg

type Tab
  = CommitsTab
  | CommentsTab
  | SettingsTab

type alias Change =
  { id : Int
  , byEmail : String
  }

type alias CommitButton =
  { name : String
  , class : String
  , iconClass : String
  , msg : Msg
  }

type alias Commit =
  { id : Int
  , summary : String
  , repository : String
  , authorName : String
  , authorGravatarHash : String
  , timestamp : String
  , isNew : Bool
  , isReviewed : Bool
  , isBeingReviewed : Bool
  , url : String
  , pendingReviewerGravatarHash : Maybe String
  , pendingReviewerEmail : Maybe String
  , reviewerGravatarHash : Maybe String
  , reviewerEmail : Maybe String
  }

type alias Comment =
  { id : Int
  , timestamp : String
  , authorGravatar : String
  , authorName : String
  , commitAuthorName : Maybe String
  , commitAuthorGravatar : Maybe String
  , commitSummary : Maybe String
  , resolved : Bool
  , resolverGravatar : Maybe String
  , body : String
  , threadIdentifier : String
  , url : String
  }

type alias Identifyable a = { a | id : Int }

type alias Model =
  { commits : List Commit
  , comments: List Comment
  , commentsToShow: List Comment
  , commitCount : Int
  , settings : Settings
  , lastClickedCommitId : Int
  , lastClickedCommentId : Int
  , commitsToShowCount : Int
  , environment : String
  , activeTab : Tab
  , connected : Connectivity
  }

type Connectivity =
  Unknown
  | Yes
  | No