# DocuMind Frontend Plan

## Scope

Build a React/Vite mock frontend with three routes:

- `/login`: email and password sign-in only.
- `/register`: name, email, and password account creation.
- `/chat`: a ChatGPT-like documentation assistant.

This scope is UI-only. It has no real authentication, API requests, persistence, streaming, or file upload.

## Design Direction

Use `client/src/shared/styles/schemablue-DESIGN.md` as the visual source of truth.

- Canvas: `#F0F4FF`; surface: `#FFFFFF`; borders: `#DBEAFE`.
- Primary actions: `#3B82F6`; source citations: `#8B5CF6`; successful retrieval: `#10B981`.
- Use Roboto Mono for brand, headings, code, and technical metadata.
- Use Roboto for body copy and assistant responses.
- Apply SchemaBlue's 4px spacing grid, 8px default radius, and restrained material-style elevation.
- Assistant responses appear as evidence cards with a subtle blue top accent. Citation links and source labels use purple relationship cues.
- Do not add gradients, decorative patterns, social-media styling, or file upload controls.

## Routing And Mock Session

- Add `react-router-dom` and use `BrowserRouter`.
- Define `/login`, `/register`, and `/chat`; redirect unknown paths to `/login`.
- Keep mock authentication state in memory only.
- A valid mock sign-in or registration submit navigates to `/chat`.
- Link `/login` to `/register` and provide a reciprocal sign-in link on `/register`.
- Signing out navigates to `/login`.
- Refreshing the page clears the mock session; visiting `/chat` then redirects to `/login`.
- Add a Vercel SPA rewrite so direct navigation and refresh work for all routes.

## Login Page

- Full-height pale-blue canvas with a centered, white, maximum 420px card.
- Include a compact DocuMind schema/node logo, a "Welcome back" heading, and product description.
- Provide email and password fields with visible labels, helper text, and inline validation.
- Provide an accessible minimal outline password visibility control that switches between eye and eye-off icons, with an updated `aria-label` and tooltip.
- Use one full-width primary "Sign in" button.
- Disable the submit button while pending and show "Signing in...".
- Show form failures in a `role="alert"` region; connect field errors with `aria-describedby`.
- Include a text link to `/register`. Do not include social sign-in or profile UI.

## Register Page

- Reuse the login page's centered SchemaBlue card, brand treatment, spacing, and input styling.
- Include name, work email, and password fields with visible labels, appropriate autocomplete values, helper text, and inline validation.
- Use the same accessible minimal password visibility control as login.
- Use one full-width primary "Create account" button; disable it while pending and show "Creating account...".
- Show form failures in a `role="alert"` region; connect field errors with `aria-describedby`.
- Include a text link to `/login` for existing users.

## Chat Page

### Desktop Layout

- Use a 280px persistent history sidebar and flexible main workspace.
- The sidebar contains the logo, a "New chat" action, mock conversations in descending recency order without date-group headings, and an account row with sign out.
- The active conversation uses a pale-blue background and a 2px primary-blue left border.
- The main workspace has a compact header without an export action, a centered message column with an 800px maximum reading width, and a sticky composer.

### Conversation

- User messages are right-aligned with primary-blue fill and white text.
- Assistant messages are left-aligned white evidence cards with response content, code support, copy action, and citations.
- The empty state explains the documentation RAG behavior and offers three or four suggested prompts.
- The composer uses a multiline textarea, a send button, and the helper text: "Answers are grounded in indexed documentation."
- Seed the UI with immutable mock conversations, messages, and citations.
- Enter sends a non-empty draft. Shift+Enter inserts a newline.
- New mock messages use local component state and reset after a page refresh.

### Responsive Behavior

- At tablet widths, the sidebar is collapsible through an accessible header control.
- Below 768px, the sidebar becomes a modal drawer with a backdrop, close control, focus trap, and Escape handling.
- Preserve 12-16px message gutters on mobile and keep the composer above mobile safe-area insets.
- Keep source text readable, truncate visual conversation labels safely, and allow long code blocks to scroll horizontally inside their own container.

## Proposed Files

```text
client/src/
  app/
    AppRouter.tsx
  features/
    auth/
      LoginPage.tsx
      LoginForm.tsx
      RegisterPage.tsx
      RegisterForm.tsx
      auth.types.ts
    chat/
      ChatPage.tsx
      chat.types.ts
      mockChat.ts
      components/
        ChatSidebar.tsx
        ChatHeader.tsx
        ConversationList.tsx
        ConversationItem.tsx
        MessageList.tsx
        MessageBubble.tsx
        AssistantResponse.tsx
        CitationList.tsx
        SuggestedPromptList.tsx
        MessageComposer.tsx
        EmptyChatState.tsx
  shared/
    components/
      Avatar.tsx
      Button.tsx
      IconButton.tsx
      Logo.tsx
      TextField.tsx
      ErrorBoundary.tsx
    styles/
      tokens.css
      globals.css
  App.tsx
  index.css
```

## Accessibility

- Use semantic `header`, `aside`, `nav`, `main`, and `form` landmarks.
- Provide one visible `h1` per page.
- Use native buttons, inputs, and textarea controls.
- Give every icon-only control an `aria-label`, tooltip, and visible focus ring.
- Use explicit labels and autocomplete values for login and registration inputs.
- Label the message feed and reserve `aria-live="polite"` for future streaming status, not full response text.
- Respect `prefers-reduced-motion` and ensure all behavior works without hover.

## Vercel And Validation

- Set Vercel Root Directory to `client`.
- Use `npm run build` and deploy `dist`.
- Add the SPA rewrite required by `BrowserRouter`.
- Verify with `npm run lint` and `npm run build`.
- Manually test login and registration validation, password visibility controls, login/register navigation, route redirects, direct route refresh, logout, message submission, Enter/Shift+Enter, and desktop/mobile layouts.
