package com.saranshmalik.rnzendeskchat;
import android.app.Activity;
import android.content.Context;
import android.graphics.Color;
import android.os.Build;
import androidx.core.content.ContextCompat;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import java.lang.String;
import java.lang.Long;
import java.lang.Double;
import java.util.*;
import javax.annotation.Nullable;
import zendesk.chat.Chat;
import zendesk.chat.ChatConfiguration;
import zendesk.chat.ChatEngine;
import zendesk.chat.ChatProvider;
import zendesk.chat.ChatSessionStatus;
import zendesk.chat.ChatState;
import zendesk.chat.ObservationScope;
import zendesk.chat.Observer;
import zendesk.chat.PreChatFormFieldStatus;
import zendesk.chat.ProfileProvider;
import zendesk.chat.Providers;
import zendesk.chat.VisitorInfo;
import zendesk.core.JwtIdentity;
import zendesk.core.AnonymousIdentity;
import zendesk.core.Identity;
import zendesk.messaging.MessagingActivity;
import zendesk.core.Zendesk;
import zendesk.support.Support;
import zendesk.support.guide.HelpCenterActivity;
import zendesk.support.guide.ViewArticleActivity;
import zendesk.support.requestlist.RequestListActivity;
import zendesk.support.request.RequestActivity;
import zendesk.support.CustomField;
import zendesk.answerbot.AnswerBot;
import zendesk.answerbot.AnswerBotEngine;
import zendesk.support.SupportEngine;
public class RNZendeskChat extends ReactContextBaseJavaModule {
  private ReactContext appContext;
  private static final String TAG = "ZendeskChat";
  public RNZendeskChat(ReactApplicationContext reactContext) {
        super(reactContext);
        appContext = reactContext;
  }
  @Override
  public String getName() {
    return "RNZendeskChat";
  }
  @ReactMethod
    public void setVisitorInfo(ReadableMap options) {
        Providers providers = Chat.INSTANCE.providers();
        if (providers == null) {
            Log.d(TAG, "Can't set visitor info, provider is null");
            return;
        }
        ProfileProvider profileProvider = providers.profileProvider();
        if (profileProvider == null) {
            Log.d(TAG, "Profile provider is null");
            return;
        }
        ChatProvider chatProvider = providers.chatProvider();
        if (chatProvider == null) {
            Log.d(TAG, "Chat provider is null");
            return;
        }
        VisitorInfo.Builder builder = VisitorInfo.builder();
        if (options.hasKey("name")) {
            builder = builder.withName(options.getString("name"));
        }
        if (options.hasKey("email")) {
            builder = builder.withEmail(options.getString("email"));
        }
        if (options.hasKey("phone")) {
            builder = builder.withPhoneNumber(options.getString("phone"));
        }
        VisitorInfo visitorInfo = builder.build();
        profileProvider.setVisitorInfo(visitorInfo, null);
        if (options.hasKey("department"))
            chatProvider.setDepartment(options.getString("department"), null);
    }
    @ReactMethod
    public void init(ReadableMap options) {
        String appId = options.getString("appId");
        String clientId = options.getString("clientId");
        String url = options.getString("url");
        // String key = options.getString("key");
        Context context = appContext;
        Zendesk.INSTANCE.init(context, url, appId, clientId);
        Support.INSTANCE.init(Zendesk.INSTANCE);
        AnswerBot.INSTANCE.init(Zendesk.INSTANCE, Support.INSTANCE);
        // Chat.INSTANCE.init(context, key);
    }
    @ReactMethod
    public void initChat(String key) {
        Context context = appContext;
        Chat.INSTANCE.init(context, key);
    }
    @ReactMethod
    public void setUserIdentity(ReadableMap options) {
        if (options.hasKey("token")) {
          Identity identity = new JwtIdentity(options.getString("token"));
          Zendesk.INSTANCE.setIdentity(identity);
        } else {
          String name = options.getString("name");
          String email = options.getString("email");
          Identity identity = new AnonymousIdentity.Builder()
                  .withNameIdentifier(name).withEmailIdentifier(email).build();
          Zendesk.INSTANCE.setIdentity(identity);
        }
    }
    @ReactMethod
    public void showHelpCenter(ReadableMap options) {
        String botName = options.hasKey("botName") ? options.getString("botName") : "Chat Bot";
        Activity activity = getCurrentActivity();
        if (options.hasKey("withChat")) {
            HelpCenterActivity.builder()
             .withEngines(ChatEngine.engine())
             .show(activity);
        } else if (options.hasKey("disableTicketCreation")) {
            HelpCenterActivity.builder()
              .withContactUsButtonVisible(false)
              .withShowConversationsMenuButton(false)
              .show(activity, ViewArticleActivity.builder()
                                                 .withContactUsButtonVisible(false)
                                                 .config());
        } else {
          CustomField customFieldOne = new CustomField(360033102052L, "3");
            HelpCenterActivity
              .builder()
              .withContactUsButtonVisible(false)
              .show(activity, RequestActivity
                .builder()
                .withTicketForm(360000986391L, Arrays.asList(customFieldOne))
                .config()
              );
        }
    }
    @ReactMethod
    public void openTicketList(){
      Activity activity = getCurrentActivity();
      RequestListActivity
        .builder()
        .withContactUsButtonVisible(false)
        .show(activity);
    }
    @ReactMethod
    public void openTicket(ReadableMap info) {
      Activity activity = getCurrentActivity();
      String phone = info.getString("phone");
      String contractNumber = info.getString("contract_number");
      String email = info.getString("email");
      String name = info.getString("name");
      String motive = info.getString("motive");
      String document = info.getString("document");
      Long subMotiveLongField = (long)info.getDouble("submotiveField");
      Long motiveFieldID = (long)info.getDouble("motiveFieldID");
      String submotive = info.getString("submotive");
      
      CustomField phoneField = new CustomField(360033143751L, phone);
      CustomField contractNumberField = new CustomField(360033057132L, contractNumber);
      CustomField emailField = new CustomField(360034437452L, email);
      CustomField nameField = new CustomField(360033143911L, name);
      CustomField motiveField = new CustomField(motiveFieldID, motive);
      CustomField documentField = new CustomField(360033102052L, document);
      CustomField submotiveField = new CustomField(subMotiveLongField, submotive);
      RequestActivity.builder().withCustomFields(Arrays.asList(phoneField, contractNumberField, emailField, nameField, motiveField, documentField, submotiveField)).show(activity);
    }
    @ReactMethod
    public void startChat(ReadableMap options) {
        Providers providers = Chat.INSTANCE.providers();
        setUserIdentity(options);
        setVisitorInfo(options);
        String botName = options.getString("botName");
        ChatConfiguration chatConfiguration = ChatConfiguration.builder()
                .withAgentAvailabilityEnabled(true)
                .withOfflineFormEnabled(true)
                .build();
        Activity activity = getCurrentActivity();
        if (options.hasKey("chatOnly")) {
           MessagingActivity.builder()
                    .withBotLabelString(botName)
                    .withEngines(ChatEngine.engine(), SupportEngine.engine())
                    .show(activity, chatConfiguration);
        } else {
            MessagingActivity.builder()
                    .withBotLabelString(botName)
                    .withEngines(AnswerBotEngine.engine(), ChatEngine.engine(), SupportEngine.engine())
                    .show(activity, chatConfiguration);
        }
    }
}