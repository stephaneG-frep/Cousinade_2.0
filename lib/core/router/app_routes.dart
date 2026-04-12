class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const createOrJoinFamily = '/family/setup';

  static const home = '/home';
  static const family = '/family';
  static const createPost = '/create-post';
  static const events = '/events';
  static const profile = '/profile';

  static const postDetail = '/post/:postId';
  static const conversations = '/conversations';
  static const chat = '/chat/:conversationId';
  static const eventDetail = '/event/:eventId';
  static const createEvent = '/events/create';
  static const editProfile = '/profile/edit';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const userGuide = '/guide';
  static const admin = '/admin';

  static String postDetailPath(String postId) => '/post/$postId';
  static String chatPath(String conversationId) => '/chat/$conversationId';
  static String eventDetailPath(String eventId) => '/event/$eventId';
}
