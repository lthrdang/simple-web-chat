import { Box, Container, Typography, Paper } from '@mui/material';
import { GoogleLogin } from '@react-oauth/google';
import { useAuth } from '../hooks/useAuth';

function Login() {
  const { login } = useAuth();

  return (
    <Container component="main" maxWidth="xs">
      <Box
        sx={{
          marginTop: 8,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <Paper 
          elevation={3} 
          sx={{ 
            padding: 4, 
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            borderRadius: 2 
          }}
        >
          <Typography component="h1" variant="h5" gutterBottom>
            Welcome to Chat App
          </Typography>
          
          <Typography variant="body2" color="text.secondary" align="center" sx={{ mb: 3 }}>
            Please sign in with your Google account to continue
          </Typography>
          
          <GoogleLogin
            onSuccess={login}
            onError={() => {
              console.error('Login Failed');
            }}
            useOneTap
            theme="filled_blue"
            text="signin_with"
            shape="pill"
            width="250px"
          />
        </Paper>
      </Box>
    </Container>
  );
}

export default Login; 