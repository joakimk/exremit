module Shared.State exposing (subscriptions, initialModel, update)

import Time exposing (inMilliseconds, second)
import Shared.Types exposing (..)
import Shared.Constants exposing (defaultCommitsToShowCount)
import Shared.Ports
import Shared.UpdateList exposing (addOrUpdateById)
import Settings.State
import Connectivity.State


subscriptions : a -> Sub Msg
subscriptions _ =
    [ Shared.Ports.commits UpdateCommits
    , Shared.Ports.comments UpdateComments
    , Shared.Ports.newOrUpdatedCommit AddOrUpdateCommit
    , Shared.Ports.newOrUpdatedComment AddOrUpdateComment
    , Shared.Ports.environment UpdateEnvironment
    , Shared.Ports.location LocationChange
    , Connectivity.State.subscriptions
    , Settings.State.subscriptions
    , (Time.every (second) StoreCurrentTime)
    , (Time.every (inMilliseconds 500) ListMoreCommits)
    , (Time.every (inMilliseconds 50) AnimateInReviewLink)
    ]
        |> Sub.batch


initialModel : Model
initialModel =
    { activeTab = CommitsTab
    , environment = "unknown"
    , settings = Settings.State.initialModel
    , commits = []
    , commitCount = 0
    , comments = []
    , commentsToShow = []
    , lastClickedCommitId = 0
    , lastClickedCommentId = 0
    , commitsToShowCount = defaultCommitsToShowCount
    , connected = Unknown
    , inReviewByYouLinkColorIndex = 0
    -- List of colors from 0 to 255 and 254 to 1. E.g. like [ 0, 1, 2, 3, 4, 5, 4, 3, 2, 1 ]
    -- We move through the list when animating, looping around
    , inReviewByYouLinkColors = List.concat [ (List.range 0 255), (List.range 254 1) ]
    , currentTime = 0
    }


update : Msg -> Model -> ( Model, Cmd a )
update msg model =
    case msg of
        UpdateConnectionStatus connected ->
            ( { model
                | connected =
                    if connected then
                        Yes
                    else
                        No
              }
            , Cmd.none
            )

        UpdateEnvironment name ->
            ( { model | environment = name }, Cmd.none )

        UpdateSettings settings ->
            ( { model | settings = settings }, Cmd.none )

        UpdateCommits commits ->
            let
                m =
                    (updateCommits model commits)
            in
                ( { m | commitsToShowCount = defaultCommitsToShowCount }, Cmd.none )

        UpdateComments comments ->
            ( { model | comments = comments }, Cmd.none )

        SwitchTab tab ->
            ( { model | activeTab = tab, commitsToShowCount = defaultCommitsToShowCount }
            , Shared.Ports.navigate (pathForTab tab)
            )

        LocationChange path ->
            ( { model | activeTab = (tabForPath path) }, Cmd.none )

        ShowCommit id ->
            ( { model | lastClickedCommitId = id }, Cmd.none )

        StoreLastClickedCommentId id ->
            ( { model | lastClickedCommentId = id }, Cmd.none )

        StoreCurrentTime time ->
            ( { model | currentTime = time }, Cmd.none )

        -- This triggers the display of more commits after the initial page load
        -- or when changing tabs. This makes the UI feel instant.
        ListMoreCommits _ ->
            if model.activeTab == CommitsTab && model.commitsToShowCount < model.commitCount then
                ( { model | commitsToShowCount = model.commitsToShowCount + 100 }, Cmd.none )
            else
                ( model, Cmd.none )

        AnimateInReviewLink time ->
            let
                numberOfColorsToMoveToEndOfList =
                    6

                colorsAtEndOfList =
                    model.inReviewByYouLinkColors |> List.take numberOfColorsToMoveToEndOfList

                newColorList =
                    List.concat [ (model.inReviewByYouLinkColors |> List.drop numberOfColorsToMoveToEndOfList), colorsAtEndOfList ]
            in
                ( { model | inReviewByYouLinkColors = newColorList }, Cmd.none )

        AddOrUpdateCommit commit ->
            let
                commits =
                    (model.commits |> addOrUpdateById commit)
            in
                ( updateCommits model commits, Cmd.none )

        AddOrUpdateComment comment ->
            ( { model | comments = model.comments |> addOrUpdateById comment }, Cmd.none )

        FocusCommitById id ->
            ( { model | lastClickedCommitId = id }, Shared.Ports.focusCommitById id )

        -- no local changes so you know if you are in sync
        -- should work fine as long as network speeds are resonable
        StartReview change ->
            ( { model | lastClickedCommitId = change.id }, pushEvent "StartReview" change )

        AbandonReview change ->
            ( model, pushEvent "AbandonReview" change )

        MarkAsReviewed change ->
            ( model, pushEvent "MarkAsReviewed" change )

        MarkAsNew change ->
            ( model, pushEvent "MarkAsNew" change )

        MarkCommentAsResolved change ->
            ( model, pushEvent "MarkCommentAsResolved" change )

        MarkCommentAsNew change ->
            ( model, pushEvent "MarkCommentAsNew" change )

        ChangeSettings msg ->
            let
                updatedSettings =
                    Settings.State.update model.settings msg
            in
                ( { model | settings = updatedSettings }, Shared.Ports.settingsChange updatedSettings )


updateCommits : Model -> List Commit -> Model
updateCommits model commits =
    { model | commits = commits, commitCount = List.length commits }


pathForTab : Tab -> String
pathForTab tab =
    case tab of
        CommitsTab ->
            "/commits"

        CommentsTab ->
            "/comments"

        SettingsTab ->
            "/settings"


tabForPath : String -> Tab
tabForPath path =
    case path of
        "/commits" ->
            CommitsTab

        "/comments" ->
            CommentsTab

        "/settings" ->
            SettingsTab

        _ ->
            CommitsTab


pushEvent : String -> Change -> Cmd a
pushEvent name change =
    Shared.Ports.outgoingCommands ( name, change )
